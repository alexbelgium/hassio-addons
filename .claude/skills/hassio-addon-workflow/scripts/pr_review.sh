#!/usr/bin/env bash
# Work through bot review comments on a PR. Resolving a thread needs the GraphQL API (the REST
# API cannot do it), which is the only reason this script exists.
#
#   pr_review.sh list    <PR>                  every inline comment, grouped
#   pr_review.sh status  <PR>                  checks + unresolved thread count
#   pr_review.sh reply   <PR> <COMMENT_ID> <text|@file>
#   pr_review.sh resolve <PR> <THREAD_ID...|--all>   --all = every unresolved, asks first
#   pr_review.sh watch   <PR> [minutes]        poll checks (run this backgrounded)
#
# Reviewers seen here: coderabbitai (deepest; reviews ~9 min after open, or on
# "@coderabbitai review"), chatgpt-codex-connector, Copilot, Codacy.
#
# Verify every claim before agreeing. Bots are frequently right and occasionally confidently
# wrong; a reproduction takes a minute and decides it either way. Push back with evidence when
# you are right — a resolved-but-wrong thread is worse than an open one.
set -uo pipefail

REPO="${HASSIO_REPO:-}"
[ -z "$REPO" ] && REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2> /dev/null)
[ -z "$REPO" ] && { echo "cannot determine repo; set HASSIO_REPO=owner/name" >&2; exit 1; }
echo "repo: $REPO" >&2
CMD="${1:-}"; PR="${2:-}"
[ -z "$CMD" ] || [ -z "$PR" ] && { sed -n '2,16p' "$0" | sed 's/^# \?//'; exit 1; }

case "$CMD" in
list)
    echo "== inline comments on #$PR =="
    gh api "repos/$REPO/pulls/$PR/comments" --paginate \
        --jq 'sort_by(.created_at)[] | "=== [\(.id)] \(.user.login) | \(.path):\(.line // .original_line) ===\n\(.body)\n"'
    echo "== review bodies =="
    gh api "repos/$REPO/pulls/$PR/reviews" \
        --jq '.[] | select(.body != "") | "--- \(.user.login) (\(.state)) ---\n\(.body[0:4000])\n"'
    ;;
status)
    gh pr checks "$PR" 2>&1 | head -15
    echo
    gh api graphql -f query="{repository(owner:\"${REPO%%/*}\",name:\"${REPO##*/}\"){pullRequest(number:$PR){reviewThreads(first:50){nodes{id isResolved path comments(first:1){nodes{author{login}}}}}}}}" \
        --jq '.data.repository.pullRequest.reviewThreads.nodes[] | "\(if .isResolved then "resolved" else "OPEN    " end) \(.id) \(.comments.nodes[0].author.login) \(.path)"'
    ;;
reply)
    ID="${3:?comment id}"; BODY="${4:?text or @file}"
    if [ "${BODY#@}" != "$BODY" ]; then
        out=$(gh api "repos/$REPO/pulls/$PR/comments/$ID/replies" -F body=@"${BODY#@}" --jq '.id' 2>&1)
        rc=$?
    else
        out=$(gh api "repos/$REPO/pulls/$PR/comments/$ID/replies" -f body="$BODY" --jq '.id' 2>&1)
        rc=$?
    fi
    # Silently "succeeding" here is worse than failing: a later session reads the transcript and
    # believes a reviewer was answered when they were not.
    if [ "$rc" -eq 0 ] && [ -n "$out" ]; then
        echo "replied to $ID (comment $out)"
    else
        echo "FAILED to reply to $ID: $out" >&2
        echo "  (top-level review bodies have different ids and cannot take replies here)" >&2
        exit 1
    fi
    ;;
resolve)
    shift 2
    ids="$*"
    if [ "${ids:-}" = "--all" ]; then
        echo "About to resolve EVERY unresolved thread. Only do this if you have read and"
        echo "answered each one — a resolved-but-wrong thread is worse than an open one."
        gh api graphql -f query="{repository(owner:\"${REPO%%/*}\",name:\"${REPO##*/}\"){pullRequest(number:$PR){reviewThreads(first:100){nodes{isResolved path comments(first:1){nodes{author{login} body}}}}}}}" \
            --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false) | "  - \(.comments.nodes[0].author.login) \(.path): \(.comments.nodes[0].body[0:90])"'
        printf 'Type "yes" to resolve all: '; read -r ok
        [ "$ok" = "yes" ] || { echo "aborted"; exit 1; }
        ids=""
    elif [ -z "$ids" ]; then
        echo "usage: pr_review.sh resolve <PR> <THREAD_ID...>   (or --all, with confirmation)" >&2
        echo "resolve each thread as you answer it; get ids from: pr_review.sh status $PR" >&2
        exit 1
    fi
    if [ -z "$ids" ]; then
        ids=$(gh api graphql -f query="{repository(owner:\"${REPO%%/*}\",name:\"${REPO##*/}\"){pullRequest(number:$PR){reviewThreads(first:50){nodes{id isResolved}}}}}" \
            --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false) | .id')
    fi
    [ -z "$ids" ] && { echo "nothing unresolved"; exit 0; }
    for id in $ids; do
        r=$(gh api graphql -f query="mutation{resolveReviewThread(input:{threadId:\"$id\"}){thread{isResolved}}}" \
            --jq '.data.resolveReviewThread.thread.isResolved' 2>&1)
        echo "  $id -> $r"
    done
    ;;
watch)
    MINS="${3:-180}"   # the addon build alone has taken ~3h; 20 was far too short
    for i in $(seq 1 "$MINS"); do
        c=$(gh pr checks "$PR" 2> /dev/null | awk '{print $1"="$2}' | tr '\n' ' ')
        if [ -z "$c" ]; then
            # Normal in the first minutes after `gh pr create`, and also whenever gh errors.
            # Calling that "settled" would report success for checks that never ran.
            echo "[$i] no checks reported yet (gh returned nothing) — still waiting"
            sleep 60; continue
        fi
        echo "[$i] $c"
        case "$c" in *pending*) sleep 60 ;; *) echo "settled"; break ;; esac
    done
    echo "note: long queues here are usually account runner contention, not your diff."
    ;;
*) echo "unknown: $CMD"; exit 1 ;;
esac
