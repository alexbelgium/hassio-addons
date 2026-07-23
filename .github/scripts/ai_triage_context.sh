#!/usr/bin/env bash
# Destination: .github/scripts/ai_triage_context.sh
#
# Builds /tmp/ai-triage/context.md so Claude does not have to explore a
# 100-addon, 34k-commit monorepo to answer one question. Everything the
# model needs is assembled here by cheap shell instead of by expensive turns.
#
# Env: GH_TOKEN, ISSUE_NUMBER, REPO

set -euo pipefail

OUT=/tmp/ai-triage
mkdir -p "$OUT"
CTX="$OUT/context.md"
: > "$CTX"

gh issue view "$ISSUE_NUMBER" --repo "$REPO" \
  --json number,title,body,author,labels,createdAt,comments > "$OUT/issue.json"

TITLE=$(jq -r '.title' "$OUT/issue.json")

# ---------------------------------------------------------------- addon slug
# Titles follow "🐛 [Immich Frame] ENV_VARS arent being picked up".
RAW=$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' <<<"$TITLE" | head -n1)
ADDON=""
if [ -n "$RAW" ]; then
  CAND=$(tr '[:upper:] ' '[:lower:]_' <<<"$RAW")
  # Directory list without checking out any of them.
  git ls-tree -d --name-only HEAD > "$OUT/dirs.txt"
  for guess in "$CAND" "${CAND//_/-}" "${CAND//_/.}"; do
    if grep -qxF "$guess" "$OUT/dirs.txt"; then ADDON="$guess"; break; fi
  done
  # Last resort: longest directory name contained in the candidate.
  if [ -z "$ADDON" ]; then
    ADDON=$(awk -v c="$CAND" 'length($0)>2 && index(c,$0){print length($0)"\t"$0}' \
            "$OUT/dirs.txt" | sort -rn | head -n1 | cut -f2)
  fi
fi

{
  echo "# Issue #${ISSUE_NUMBER}"
  echo
  echo "Repo: ${REPO}"
  echo "Addon resolved from title: ${ADDON:-UNRESOLVED}"
  echo
  echo "## Title"
  echo "$TITLE"
  echo
  echo "## Author"
  jq -r '.author.login' "$OUT/issue.json"
  echo
  echo "## Body"
  echo '```'
  jq -r '.body // "(empty)"' "$OUT/issue.json"
  echo '```'
  echo
  echo "## Existing comments (in order)"
  jq -r '.comments[]? | "### @\(.author.login)\n\(.body)\n"' "$OUT/issue.json"
  echo
  echo "## Existing labels"
  jq -r '[.labels[]?.name] | join(", ")' "$OUT/issue.json"
} >> "$CTX"

# ------------------------------------------------------------- addon sources
if [ -n "$ADDON" ]; then
  git sparse-checkout set --no-cone .github/prompts .github/scripts "$ADDON" || true

  {
    echo
    echo "## Addon files: ${ADDON}/"
    for f in config.yaml config.json Dockerfile CHANGELOG.md DOCS.md README.md; do
      [ -f "$ADDON/$f" ] || continue
      echo
      echo "### ${ADDON}/${f}"
      echo '```'
      head -c 8000 "$ADDON/$f"
      echo '```'
    done

    echo
    echo "## Recent commits touching ${ADDON}/"
    git log -n 15 --date=short --pretty='- %ad %h %s' -- "$ADDON" 2>/dev/null || true
  } >> "$CTX"
fi

# -------------------------------------------------------- possible duplicates
{
  echo
  echo "## Similar existing issues (candidate duplicates)"
  KEYWORDS=$(tr -cs '[:alnum:]' ' ' <<<"$TITLE" \
             | tr '[:upper:]' '[:lower:]' \
             | tr ' ' '\n' | awk 'length($0)>3' | head -n6 | paste -sd' ')
  gh search issues --repo "$REPO" --limit 15 \
     --json number,title,state,url -- "$KEYWORDS" 2>/dev/null \
    | jq -r '.[] | "- #\(.number) [\(.state)] \(.title)"' \
    || echo "(search unavailable)"
} >> "$CTX"

echo "context bundle: $(wc -c < "$CTX") bytes, addon=${ADDON:-none}"
