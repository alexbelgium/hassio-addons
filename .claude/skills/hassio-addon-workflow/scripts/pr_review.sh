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
# watch exits 0 when every blocking check passed *or was skipped* — a PR touching no add-on
# skips all three gates, and it says so — 1 on failure, 2 if it ran out of minutes. Codacy is
# advisory here: printed every poll, excluded from the verdict.
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
[ -z "$REPO" ] && {
    echo "cannot determine repo; set HASSIO_REPO=owner/name" >&2
    exit 1
}
echo "repo: $REPO" >&2
CMD="${1:-}"
PR="${2:-}"
[ -z "$CMD" ] || [ -z "$PR" ] && {
    sed -n '2,20p' "$0" | sed 's/^# \?//'
    exit 1
}

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
        ID="${3:?comment id}"
        BODY="${4:?text or @file}"
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
            printf 'Type "yes" to resolve all: '
            read -r ok
            [ "$ok" = "yes" ] || {
                echo "aborted"
                exit 1
            }
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
        [ -z "$ids" ] && {
            echo "nothing unresolved"
            exit 0
        }
        rfail=0
        for id in $ids; do
            r=$(gh api graphql -f query="mutation{resolveReviewThread(input:{threadId:\"$id\"}){thread{isResolved}}}" \
                --jq '.data.resolveReviewThread.thread.isResolved' 2>&1)
            echo "  $id -> $r"
            [ "$r" = "true" ] || rfail=1
        done
        # exiting 0 on a failed mutation would let a session believe threads were resolved
        exit "$rfail"
        ;;
    watch)
        MINS="${3:-180}" # the addon build alone has taken ~3h; 20 was far too short
        # Checks that are red on essentially every add-on PR here and gate nothing: master carries no
        # branch protection, and #3019, #3044 and #3050 all merged with Codacy failing. They are kept
        # out of the verdict but always printed, so the reader still sees them and can judge. This is
        # deliberately a denylist of known noise, not an allowlist of blocking checks — a job added to
        # CI later counts as blocking until someone puts it here on purpose.
        ADVISORY_CHECKS="Codacy Static Code Analysis" # one per line if more are ever added
        wfail=2                                       # not 0: running out of minutes with checks still pending is not a pass
        c=""
        bstates=""
        adv=""
        for i in $(seq 1 "$MINS"); do
            # gh pr checks emits TAB-separated columns with no header when its output is not a TTY,
            # which inside this $(... | awk) it never is. (Attached to a terminal it prints a wholly
            # different ANSI table; --json would be sturdier still but does not exist before gh 2.36,
            # and 2.23 ships here.) Every blocking gate has spaces in its name — "Addon linting
            # (wger)", "Test addon build (wger)" — so awk's default separator split them on
            # whitespace: "Codacy Static Code Analysis<TAB>fail" became "Codacy=Static" and the state
            # column was never read at all. watch printed "all passing" on a red #3044 and on #3042
            # with the linter failing, and could not see a pending build either.
            # If that format ever does change, the allowlist below fails safe rather than passing: a
            # header row lands in the failure branch, and a space-aligned table parses to no rows,
            # which keeps watch waiting instead of returning 0.
            rows=$(gh pr checks "$PR" 2> /dev/null | awk -F'\t' -v ADV="$ADVISORY_CHECKS" '
            BEGIN { n = split(ADV, a, "\n"); for (j = 1; j <= n; j++) adv[a[j]] = 1 }
            NF >= 2 { print (($1 in adv) ? "A" : "B") "\t" $1 "=" $2 "\t" $2 }')
            if [ -z "$rows" ]; then
                # Normal in the first minutes after `gh pr create`, and also whenever gh errors.
                # Calling that "settled" would report success for checks that never ran.
                echo "[$i] no checks reported yet (gh returned nothing) — still waiting"
                sleep 60
                continue
            fi
            c=$(printf '%s\n' "$rows" | cut -f2 | tr '\n' ' ')
            echo "[$i] $c"
            # Judge the state column only, never the joined name=state line: a check whose NAME
            # contains "fail" must not read as a failure.
            bstates=$(printf '%s\n' "$rows" | awk -F'\t' '$1 == "B" { print $3 }' | tr '\n' ' ')
            adv=$(printf '%s\n' "$rows" | awk -F'\t' '$1 == "A" { print $2 }' | tr '\n' ' ')
            if [ -z "$bstates" ]; then
                echo "  only advisory checks have reported — no blocking check has run yet"
                sleep 60
                continue
            fi
            # Allowlist the good states rather than denylisting the bad ones: an unrecognised state
            # must land in the failure branch, because falling through to "passing" is this command's
            # worst outcome.
            nbad=0
            npend=0
            for s in $bstates; do
                case "$s" in
                    pass | skipping) ;;
                    pending) npend=$((npend + 1)) ;;
                    *) nbad=$((nbad + 1)) ;;
                esac
            done
            if [ "$nbad" -gt 0 ]; then
                echo "settled — blocking checks FAILED:"
                printf '%s\n' "$rows" \
                    | awk -F'\t' '$1 == "B" && $3 != "pass" && $3 != "skipping" && $3 != "pending" { print "    " $2 }'
                wfail=1
                break
            elif [ "$npend" -gt 0 ]; then
                sleep 60
                continue
            else
                echo "settled — blocking checks passing"
                wfail=0
                break
            fi
        done
        [ "$wfail" -eq 2 ] && echo "gave up after ${MINS}m, checks still unsettled — NOT a pass"
        # Printed on pass and on failure alike: it is excluded from the verdict, not hidden.
        [ -n "$adv" ] && echo "  advisory (non-blocking, not counted in the verdict): $adv"
        # A PR touching no */config.* skips the CHANGELOG, linter and build jobs outright (#3018).
        case " $bstates " in *" skipping "*) echo "  ...of which some were SKIPPED — a skipped job tested nothing" ;; esac
        echo "note: long queues here are usually account runner contention, not your diff."
        exit "$wfail"
        ;;
    *)
        echo "unknown: $CMD"
        exit 1
        ;;
esac
