#!/usr/bin/env bash
#
# Build-time helper for the BirdNET-Go "from source" Home Assistant add-on.
#
# Clones the alexbelgium/birdnet-go fork, fast-forwards its main onto the
# tphakala/birdnet-go upstream (so main is fully synced with upstream), then
# merges every OPEN, NON-DRAFT ("in review") pull request on top - producing a
# source tree that is upstream main plus all work currently under review.
#
# The merged tree (including .git, which the BirdNET-Go build uses for version
# stamping) is written to the directory given as $1 so the Docker build can
# compile it.
#
# Environment:
#   BIRDNET_FORK       owner/repo of the fork           (default alexbelgium/birdnet-go)
#   BIRDNET_UPSTREAM   owner/repo of the upstream        (default tphakala/birdnet-go)
#   GH_TOKEN / GITHUB_TOKEN  optional, lifts the 60 req/h unauthenticated
#                            GitHub API rate limit; not required for public repos
#
set -euo pipefail

TARGET_DIR="${1:?usage: merge-prs.sh <target-dir>}"

FORK="${BIRDNET_FORK:-alexbelgium/birdnet-go}"
UPSTREAM="${BIRDNET_UPSTREAM:-tphakala/birdnet-go}"

FORK_URL="https://github.com/${FORK}.git"
UPSTREAM_URL="https://github.com/${UPSTREAM}.git"
API_URL="https://api.github.com/repos/${FORK}/pulls?state=open&per_page=100"

# Optional token to lift the unauthenticated GitHub API rate limit.
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

log() { echo ">>> $*"; }

git config --global user.email "addon-builder@users.noreply.github.com"
git config --global user.name "BirdNET-Go Addon Builder"
git config --global advice.detachedHead false

log "Cloning fork ${FORK}"
git clone "${FORK_URL}" "${TARGET_DIR}"
cd "${TARGET_DIR}"
git checkout main

log "Syncing main with upstream ${UPSTREAM}"
git remote add upstream "${UPSTREAM_URL}"
git fetch --no-tags upstream main
# --no-ff keeps an explicit sync commit; a no-op when main is already current.
git merge --no-edit --no-ff upstream/main

log "Querying open non-draft PRs from ${FORK}"
auth_header=()
if [ -n "${GH_TOKEN}" ]; then
    auth_header=(-H "Authorization: Bearer ${GH_TOKEN}")
fi

pr_json="$(curl -fsSL "${auth_header[@]}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${API_URL}")"

# Open, non-draft PRs only ("in review"), oldest first for a stable merge order.
mapfile -t prs < <(echo "${pr_json}" \
    | jq -r 'sort_by(.number) | .[] | select(.draft == false) | "\(.number)\t\(.head.sha)\t\(.title)"')

if [ "${#prs[@]}" -eq 0 ]; then
    log "No open non-draft PRs to merge - building upstream-synced main only"
else
    log "Merging ${#prs[@]} open non-draft PR(s)"
fi

for entry in "${prs[@]}"; do
    number="$(printf '%s' "${entry}" | cut -f1)"
    sha="$(printf '%s' "${entry}" | cut -f2)"
    title="$(printf '%s' "${entry}" | cut -f3-)"
    log "Merging PR #${number}: ${title} (${sha})"
    # Fetch the PR head commit by number; works unauthenticated for public repos.
    git fetch --no-tags origin "refs/pull/${number}/head"
    if ! git merge --no-edit --no-ff -m "Merge PR #${number}: ${title}" "${sha}"; then
        echo "!!! Merge conflict while merging PR #${number} (${title})." >&2
        echo "!!! Resolve the conflict in the fork or pause this PR, then rebuild." >&2
        git merge --abort || true
        exit 1
    fi
done

log "Merged HEAD: $(git rev-parse --short HEAD)"
log "Source tree ready at ${TARGET_DIR}"
