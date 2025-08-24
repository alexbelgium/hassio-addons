#!/bin/bash
set -e
update=yes
if [[ "$update" = "yes" ]]; then
    repo="https://github.com/alexbelgium/BirdNET-Pi.git"
    # repo="https://github.com/Nachtzuster/BirdNET-Pi.git"
    branch="main"
    echo "Update with $branch of $repo"

    temp_dir="$(mktemp -d)"
    target_dir="/home/${USER:-pi}/BirdNET-Pi"

    # Parse owner/repo from the URL
    _url_no_git="${repo%.git}"
    _path="${_url_no_git#https://github.com/}"
    owner="${_path%%/*}"
    reponame="${_path#*/}"

    # --- helper: list open PRs via GitHub API (unauthenticated) ----------------
    list_open_prs() {
        # prints PR numbers, one per line; returns non-zero if none or curl missing
        command -v curl > /dev/null 2>&1 || return 1
        local page=1 per_page=100 out
        local -a all=() chunk=()
        while :; do
            out="$(curl -fsSL "https://api.github.com/repos/${owner}/${reponame}/pulls?state=open&per_page=${per_page}&page=${page}")" || break
            [[ -z "$out" || "$out" == "[]" ]] && break
            if command -v jq > /dev/null 2>&1; then
                mapfile -t chunk < <(printf '%s' "$out" | jq -r '.[] | select(.draft == false) | .number')
            else
                # Fallback JSON scraping if jq is unavailable
                mapfile -t chunk < <(printf '%s' "$out" | grep -o '"number":[[:space:]]*[0-9]\+' | grep -o '[0-9]\+')
            fi
            ((${#chunk[@]} == 0)) && break
            all+=("${chunk[@]}")
            ((${#chunk[@]} < per_page)) && break
            ((page++))
        done
        ((${#all[@]} == 0)) && return 1
        printf '%s\n' "${all[@]}"
    }

    # --- clone base ------------------------------------------------------------
    git clone --quiet --branch "$branch" "$repo" "$temp_dir"
    pushd "$temp_dir" > /dev/null
    git fetch --quiet origin
    git config user.name "Local PR Aggregator"
    git config user.email "local@example.invalid"
    git checkout -B with-open-prs "origin/${branch}"

    # --- fetch & merge only OPEN PRs -------------------------------------------
    mapfile -t prs < <(list_open_prs || true)
    if ((${#prs[@]})); then
        # Sort numerically (oldest first)
        IFS=$'\n' prs=($(sort -n <<< "${prs[*]}"))
        unset IFS
        echo "Open PR(s): ${prs[*]}"

        for pr in "${prs[@]}"; do
            echo "Fetching PR #${pr}…"
            if git fetch --quiet origin "pull/${pr}/head:pr-${pr}"; then
                echo "Merging PR #${pr} into with-open-prs…"
                if git merge --no-ff -X theirs --no-edit "pr-${pr}"; then
                    echo "✓ merged PR #${pr}"
                else
                    echo "! Conflict merging PR #${pr}; aborting and skipping."
                    git merge --abort || true
                    git reset --hard
                    git checkout with-open-prs
                fi
            else
                echo "! Could not fetch refs for PR #${pr}; skipping."
            fi
        done
    else
        echo "No open PRs detected (API unavailable or none open)."
    fi

    popd > /dev/null
    rm -rf "$target_dir"
    mv "$temp_dir" "$target_dir"
fi
