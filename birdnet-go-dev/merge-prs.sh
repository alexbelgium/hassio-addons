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
# With --check the script does not build anything: it performs the exact same
# merge sequence, skips (instead of failing on) every conflicting PR, and prints
# one "!!! CONFLICT pr=#N conflicts-with=... files=... " line per offender before
# exiting 2. Use it to find conflicts *before* a build burns on them. This is a
# different question from GitHub's `mergeable` field, which compares a PR against
# its own base ref - for a stacked PR that base is another feature branch (often
# stale, sometimes belonging to a closed PR), so GitHub can report CLEAN for a PR
# that does not merge onto main at all.
#
# Environment:
#   BIRDNET_FORK       owner/repo of the fork           (default alexbelgium/birdnet-go)
#   BIRDNET_UPSTREAM   owner/repo of the upstream        (default tphakala/birdnet-go)
#   GH_TOKEN / GITHUB_TOKEN  optional, lifts the 60 req/h unauthenticated
#                            GitHub API rate limit; not required for public repos
#
set -euo pipefail

CHECK_ONLY="${MERGE_PRS_CHECK:-0}"
TARGET_DIR=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=1 ;;
        -*)
            echo "unknown option: $1" >&2
            exit 64
            ;;
        *)
            # Last-one-wins would silently clone into the wrong directory if a caller ever
            # appended an argument; the pre-flag script used "${1}", so refuse rather than
            # quietly change which operand counts.
            if [ -n "${TARGET_DIR}" ]; then
                echo "usage: merge-prs.sh [--check] <target-dir>" >&2
                exit 64
            fi
            TARGET_DIR="$1"
            ;;
    esac
    shift
done
: "${TARGET_DIR:?usage: merge-prs.sh [--check] <target-dir>}"

FORK="${BIRDNET_FORK:-alexbelgium/birdnet-go}"
UPSTREAM="${BIRDNET_UPSTREAM:-tphakala/birdnet-go}"

FORK_URL="https://github.com/${FORK}.git"
UPSTREAM_URL="https://github.com/${UPSTREAM}.git"
API_URL="https://api.github.com/repos/${FORK}/pulls?state=open&per_page=100"

# Optional token to lift the unauthenticated GitHub API rate limit.
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

log() { echo ">>> $*"; }

# Conflicting PRs collected in --check mode: "number|scope|files|title".
conflicting=()

LOCKFILE="frontend/package-lock.json"

# The single place that decides whether a conflicted merge is still acceptable.
# package-lock.json is generated content and stacked PRs can carry an older copy even when
# their source changes merge cleanly, so keep the lockfile already assembled on the base side
# — but only when it is the sole conflict. Any source conflict stays fatal.
# Returns 0 when it resolved and committed such a merge, 1 when the conflict is real.
# BOTH the real merge and the --check probe must go through here: when only the real merge
# applied the policy, the probe called a PR "conflicts-with=main" that the build would have
# merged fine, and printed the opposite remediation to the true one.
resolve_sole_lockfile() {
    local dir="$1"
    local -a conflicted
    mapfile -t conflicted < <(git -C "${dir}" diff --name-only --diff-filter=U)
    if [ "${#conflicted[@]}" -ne 1 ] || [ "${conflicted[0]}" != "${LOCKFILE}" ]; then
        return 1
    fi
    log "Resolving generated ${LOCKFILE} conflict using the base tree"
    git -C "${dir}" checkout --ours -- "${LOCKFILE}" || return 1
    git -C "${dir}" add "${LOCKFILE}" || return 1
    git -C "${dir}" commit --no-edit > /dev/null || return 1
}

# Does ${1} merge cleanly onto the pristine upstream-synced main? Probed in a
# throwaway worktree so the accumulated tree is left untouched. Tells apart a PR
# that is simply stale against main (fixable inside that PR's own branch) from
# one that only clashes with another open PR (needs a cross-PR decision).
merges_onto_main() {
    local sha="$1" tmpdir probe rc=0
    tmpdir="$(mktemp -d)"
    probe="${tmpdir}/probe"
    git worktree add --quiet --detach "${probe}" "${MAIN_SYNCED}"
    if ! git -C "${probe}" merge --no-edit --no-ff -m probe "${sha}" > /dev/null 2>&1; then
        # Same policy as the real merge, or this misclassifies a lockfile-only clash.
        resolve_sole_lockfile "${probe}" > /dev/null 2>&1 || rc=1
    fi
    git worktree remove --force "${probe}" > /dev/null 2>&1 || true
    # worktree remove only takes the child back; without this the mktemp parent is left behind
    # on every checked conflict.
    rmdir "${tmpdir}" > /dev/null 2>&1 || true
    return "${rc}"
}

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
MAIN_SYNCED="$(git rev-parse HEAD)"

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
        mapfile -t conflicted_files < <(git diff --name-only --diff-filter=U)

        if resolve_sole_lockfile .; then
            : # generated lockfile only - the merge is committed and the build continues
        else
            echo "!!! Merge conflict while merging PR #${number} (${title})." >&2
            if [ "${#conflicted_files[@]}" -gt 0 ]; then
                printf '!!! Conflicting file: %s\n' "${conflicted_files[@]}" >&2
            fi
            git merge --abort || true

            if [ "${CHECK_ONLY}" = "1" ]; then
                scope="accumulated"
                merges_onto_main "${sha}" || scope="main"
                conflicting+=("${number}|${scope}|${conflicted_files[*]:-}|${title}")
                log "check mode: skipping PR #${number}, continuing with the rest"
                continue
            fi

            echo "!!! Resolve the conflict in the fork or pause this PR, then rebuild." >&2
            exit 1
        fi
    fi
done

if [ "${CHECK_ONLY}" = "1" ]; then
    if [ "${#conflicting[@]}" -eq 0 ]; then
        log "CHECK OK: every open non-draft PR merges into the combined build tree"
        exit 0
    fi
    echo "!!! CHECK FAILED: ${#conflicting[@]} PR(s) would break the add-on build" >&2
    for entry in "${conflicting[@]}"; do
        IFS='|' read -r number scope files title <<< "${entry}"
        echo "!!! CONFLICT pr=#${number} conflicts-with=${scope} files=${files} title=${title}" >&2
    done
    echo "!!! conflicts-with=main     -> the PR is stale against main; merge main into its branch and resolve there." >&2
    echo "!!! conflicts-with=accumulated -> the PR only clashes with another open PR; decide which one owns the hunk." >&2
    exit 2
fi

log "Merged HEAD: $(git rev-parse --short HEAD)"
log "Source tree ready at ${TARGET_DIR}"
