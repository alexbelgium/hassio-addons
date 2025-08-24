#!/usr/bin/env bash

set -euo pipefail

TARGET_BRANCH="main"

# Make sure we are in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Not a git repository"
  exit 1
fi

# Get list of open, non-draft PR numbers via GitHub API
echo "🔍 Fetching open PRs..."
mapfile -t PRS < <(curl -s "https://api.github.com/repos/alexbelgium/BirdNET-Pi/pulls?state=open&per_page=100" \
  | jq -r '.[] | select(.draft==false) | .number')

if [[ ${#PRS[@]} -eq 0 ]]; then
  echo "✅ No open non-draft PRs found."
  exit 0
fi

echo "Found PRs: ${PRS[*]}"

# Update local repo
git fetch origin
git checkout "$TARGET_BRANCH"
git pull origin "$TARGET_BRANCH"

# Merge each PR
for pr in "${PRS[@]}"; do
  echo "=== Merging PR #$pr ==="

  # Fetch PR branch from GitHub refs
  git fetch origin pull/"$pr"/head:pr-"$pr"

  # Merge into target branch, no fast-forward (like GitHub)
  if ! git merge --no-ff --no-edit "pr-$pr"; then
    echo "⚠️ Merge conflict in PR #$pr."
    echo "   Resolve manually, then run: git merge --continue"
    echo "   After resolving, re-run this script to finish remaining PRs."
    exit 1
  fi
done

echo "✅ All open non-draft PRs merged into $TARGET_BRANCH"
