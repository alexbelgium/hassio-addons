#!/usr/bin/env bash
# Orient before starting add-on work: what tools exist, are we inside the running add-on, and
# — the one that actually bites — does the checkout match what is running?
#
# Usage: preflight.sh [repo-path] [addon-slug]
set -uo pipefail

REPO="${1:-/data/claude/hassio-addons}"
SLUG="${2:-}"

echo "== tools =="
for c in gh git codex rtk headroom tokensave shellcheck hadolint yamllint python3 jq; do
    printf '  %-11s %s\n' "$c" "$(command -v "$c" > /dev/null 2>&1 && echo yes || echo MISSING)"
done
[ -x /data/codex/bin/codex-real ] && echo "  codex-real  yes (prefer: codex exec --model gpt-5.6-sol)"

echo
echo "== running add-on =="
if [ -n "${BUILD_VERSION:-}" ]; then
    echo "  BUILD_VERSION=$BUILD_VERSION   HOME=${HOME:-?}"
    echo "  -> live measurement is possible; see measure.sh"
else
    echo "  not inside a running add-on (no BUILD_VERSION); source-only analysis"
fi

echo
echo "== repo =="
# git-aware check: in a worktree .git is a file, not a directory
if ! git -C "$REPO" rev-parse --git-dir > /dev/null 2>&1; then
    echo "  no git repo at $REPO"
    exit 0
fi
cd "$REPO" || exit 0
branch=$(git branch --show-current 2> /dev/null || echo "(detached)")
echo "  path=$REPO"
echo "  branch=$branch"

# Another session may be mid-operation in this shared checkout.
echo "  recent reflog (entries you did not make mean another session is active):"
git reflog --date=iso -3 2> /dev/null | sed 's/^/    /'

# The trap this exists for: a stale branch looks entirely normal.
if [ -n "${BUILD_VERSION:-}" ]; then
    # Hostname is <8-hex>-<slug-with-dashes>. Anchor the hex to 8 chars: an unanchored
    # [0-9a-f]* also eats real prefixes (dab-radio -> radio, cafe-monitor -> monitor).
    # Slugs may legitimately contain dashes (birdnet-go), so try both forms.
    if [ -z "$SLUG" ] && [ -n "${HOSTNAME:-}" ]; then
        base=$(printf '%s' "$HOSTNAME" | sed 's/^[0-9a-f]\{8\}-//')
        for cand in "$(printf '%s' "$base" | tr '-' '_')" "$base"; do
            [ -f "$REPO/$cand/config.yaml" ] && { SLUG="$cand"; break; }
        done
        [ -z "$SLUG" ] && SLUG="$base"
    fi
    cfg="$REPO/$SLUG/config.yaml"
    if [ ! -f "$cfg" ]; then
        echo
        echo "  could not find $SLUG/config.yaml — pass the slug as \$2 to enable the"
        echo "  revision check (this is the check the script exists for)." >&2
        exit 3
    fi
    if [ -f "$cfg" ]; then
        here=$(grep -E '^version:' "$cfg" | head -1 | tr -d "\"'" | awk '{print $2}')
        echo
        echo "  $SLUG/config.yaml version = $here"
        echo "  running image BUILD_VERSION = $BUILD_VERSION"
        if [ "$here" = "$BUILD_VERSION" ]; then
            echo "  MATCH — this checkout corresponds to the running image."
        else
            echo "  MISMATCH — this branch is NOT what is running."
            git fetch origin master --quiet 2> /dev/null
            master=$(git show origin/master:"$SLUG/config.yaml" 2> /dev/null |
                grep -E '^version:' | head -1 | tr -d "\"'" | awk '{print $2}')
            echo "  origin/master version = ${master:-unknown}"
            echo "  -> work from origin/master; analysing this branch will mislead you."
            echo
            echo "== suggested isolated worktree (/tmp is noexec; use /data) =="
            echo "  git worktree add --detach /data/claude/.work/<task> origin/master"
            echo "  NOTE: never 'git stash' under /data/claude — refs/stash is shared."
            exit 2
        fi
    fi
fi

echo
echo "== suggested isolated worktree (/tmp is noexec; use /data) =="
echo "  git worktree add --detach /data/claude/.work/<task> origin/master"
echo "  NOTE: never 'git stash' under /data/claude — refs/stash is shared across worktrees."
