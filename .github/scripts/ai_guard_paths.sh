#!/usr/bin/env bash
# Destination: .github/scripts/ai_guard_paths.sh
#
# Belt-and-braces enforcement of the one rule every AI fix prompt is told
# never to break: no add-on fix may touch `.github/` or `.templates/`, because
# those are inherited by all 100+ add-ons — a change there is a repo-wide
# incident, not a per-add-on fix. The prompts forbid it; this script is what
# actually enforces it after the model finishes, on the PRs it opened.
#
# Any AI PR that touches a protected path is pulled out of review (converted
# back to draft), labelled `ai:blocked`, and commented on. This is shared by
# every tier that can open or push to an `ai-fix/` PR (tiers 2 and 3, and the
# CodeRabbit follow-up) so the rule is defined and fixed in exactly one place.
#
# Env:
#   GH_TOKEN   (required) — token with pull-requests:write on REPO
#   REPO       (required) — owner/name
#   PR_NUMBER  (optional) — check only this PR; if unset, scan every open
#                           `ai-fix/` PR in the repo.

set -euo pipefail

: "${REPO:?REPO must be set}"
: "${GH_TOKEN:?GH_TOKEN must be set}"

PROTECTED='^(\.github/|\.templates/)'

if [ -n "${PR_NUMBER:-}" ]; then
    PRS="$PR_NUMBER"
else
    # gh pr list applies --limit before the headRefName filter, so a low cap
    # could silently drop older ai-fix/ PRs once total open PRs (of any kind)
    # grow past it. 300 is far above anything this repo runs; gh paginates.
    PRS=$(gh pr list --repo "$REPO" --state open --limit 300 \
        --json number,headRefName \
        --jq '.[] | select(.headRefName|startswith("ai-fix/")) | .number')
fi

for pr in $PRS; do
    [ -n "$pr" ] || continue
    BAD=$(gh pr diff "$pr" --repo "$REPO" --name-only | grep -E "$PROTECTED" || true)
    if [ -n "$BAD" ]; then
        echo "::error::PR #$pr touches protected paths:"
        echo "$BAD"
        # Ensure the label exists before adding it — with set -e a missing
        # label would abort the whole loop and skip any PRs behind this one.
        gh label create "ai:blocked" --repo "$REPO" --color ededed >/dev/null 2>&1 || true
        gh pr ready "$pr" --repo "$REPO" --undo || true
        gh pr edit "$pr" --repo "$REPO" --add-label "ai:blocked"
        gh pr comment "$pr" --repo "$REPO" --body \
            "Blocked automatically: this PR modifies shared infrastructure (\`.github/\` or \`.templates/\`), which is inherited by every add-on in the repo. Needs manual review before it goes anywhere."
    fi
done
