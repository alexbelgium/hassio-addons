#!/usr/bin/env bash
# Print one section of references/traps.md.
#
# traps.md is ~18 KB and every section but one is irrelevant to any given edit: a shell fix needs
# 642 bytes of it, a Dockerfile fix 2.6 KB, and "CI and review bots" — 35% of the file — is needed
# at steps 7-8 and never at step 4. A markdown anchor cannot be loaded on its own, so reading the
# file to reach one section pays for all of them. This prints just the section, so the routing
# table in SKILL.md step 4 costs what it claims to.
#
# Usage: traps.sh <keyword>   # substring of a section heading, case-insensitive
#        traps.sh             # list the sections
set -uo pipefail

TRAPS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/references/traps.md"
[ -f "$TRAPS" ] || {
    echo "not found: $TRAPS" >&2
    exit 1
}

# The Contents list duplicates the headings; grep the headings themselves so the list cannot drift.
list() {
    echo "sections (pass any substring):"
    grep '^## ' "$TRAPS" | grep -v '^## Contents' | sed 's/^## /  /'
}

[ $# -eq 0 ] && {
    list
    exit 0
}

# awk over exact heading text: section names contain '/' and other characters that would need
# escaping in a sed address, and a keyword matching several headings should be an error, not a
# silent pick of the first.
mapfile -t matches < <(grep '^## ' "$TRAPS" | grep -v '^## Contents' \
    | grep -iF -- "$1" | sed 's/^## //')

case "${#matches[@]}" in
    0)
        echo "no section matching '$1'" >&2
        list >&2
        exit 1
        ;;
    1) ;;
    *)
        echo "'$1' matches ${#matches[@]} sections — be more specific:" >&2
        printf '  %s\n' "${matches[@]}" >&2
        exit 1
        ;;
esac

awk -v want="## ${matches[0]}" '
    $0 == want { inside = 1; print; next }
    inside && /^## / { exit }
    inside { print }
' "$TRAPS"
