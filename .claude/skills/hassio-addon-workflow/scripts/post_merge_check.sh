#!/usr/bin/env bash
# After a PR merges: wait for the push Builder run of its merge commit, then confirm the PR's
# files on master still match the merge commit (the builder reverts merges whose build fails,
# sometimes for reasons unrelated to the diff — references/traps.md#ci-and-review-bots).
#
#   post_merge_check.sh <PR> [minutes]     default 60; run it backgrounded
#
# Exit 0: built (or no build needed) and the change is on master.
# Exit 1: build failed, or master no longer matches the merge commit. On a build failure the
#         failed-job log is saved and its path printed: hand that file to a `scout` (Haiku) to
#         digest, never read it whole, then fix on a new branch.
# Exit 2: ran out of minutes, or no Builder run appeared for a PR that changed a config.* file.
set -uo pipefail

REPO="${HASSIO_REPO:-}"
[ -z "$REPO" ] && REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2> /dev/null)
[ -z "$REPO" ] && { echo "cannot determine repo; set HASSIO_REPO=owner/name" >&2; exit 1; }
PR="${1:-}"; MINUTES="${2:-60}"
[ -z "$PR" ] && { sed -n '2,13p' "$0" | sed 's/^# \?//'; exit 1; }

read -r STATE SHA < <(gh pr view "$PR" -R "$REPO" --json state,mergeCommit --jq '"\(.state) \(.mergeCommit.oid // "")"')
[ "$STATE" != "MERGED" ] && { echo "#$PR is $STATE, not merged"; exit 1; }
mapfile -t FILES < <(gh pr view "$PR" -R "$REPO" --json files --jq '.files[].path')
echo "#$PR merged as ${SHA:0:9}; ${#FILES[@]} file(s)"

# The Builder only runs on pushes touching a top-level */config.* file
if printf '%s\n' "${FILES[@]}" | grep -qE '^[^/]+/config\.[a-z]+$'; then
    deadline=$((SECONDS + MINUTES * 60)); run=""
    while [ "$SECONDS" -lt "$deadline" ]; do
        read -r run status conclusion < <(gh api "repos/$REPO/actions/runs?head_sha=$SHA&event=push" \
            --jq '[.workflow_runs[] | select(.name == "Builder")][0] // {} | "\(.id // "") \(.status // "") \(.conclusion // "")"')
        if [ -z "$run" ] && [ "$SECONDS" -gt 600 ]; then
            echo "BUILD: no Builder run for ${SHA:0:9} after 10 min ([nobuild] in the message?)"; exit 2
        fi
        [ "$status" = "completed" ] && break
        sleep 60
    done
    [ "${status:-}" != "completed" ] && { echo "BUILD: run ${run:-none} still ${status:-pending} after ${MINUTES} min"; exit 2; }
    if [ "$conclusion" != "success" ]; then
        log="${TMPDIR:-/tmp}/builder-${PR}-${run}.log"
        gh run view "$run" -R "$REPO" --log-failed > "$log" 2>&1
        echo "BUILD FAILED: run $run ($conclusion) https://github.com/$REPO/actions/runs/$run"
        gh run view "$run" -R "$REPO" --json jobs --jq '.jobs[] | select(.conclusion == "failure") | "  failed job: \(.name)"'
        echo "  log: $log ($(wc -l < "$log") lines) — digest with a scout, do not read whole"
        exit 1
    fi
    echo "BUILD: run $run succeeded"
else
    echo "BUILD: not triggered (no top-level config.* changed)"
fi

# Fetch after the build: a revert lands at the end of the failing run
git fetch -q origin master
if git diff --quiet "$SHA" origin/master -- "${FILES[@]}"; then
    echo "MASTER: #$PR's files match the merge commit — done"
    exit 0
fi
echo "MASTER: #$PR's files differ from the merge commit. Commits since, on those paths:"
git log --oneline "$SHA"..origin/master -- "${FILES[@]}" | head -10
exit 1
