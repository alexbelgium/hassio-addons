#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/master}"
output_file="${GITHUB_OUTPUT:-/dev/stdout}"
max_files="${AI_MAX_CHANGED_FILES:-25}"
max_lines="${AI_MAX_CHANGED_LINES:-2000}"
request_category="${AI_REQUEST_CATEGORY:-}"
expected_addon="${AI_EXPECTED_ADDON:-}"

read_version() {
    local ref="$1"
    local file="$2"

    case "$file" in
        *.json)
            if [[ "$ref" == "WORKTREE" ]]; then
                jq -r '.version // empty' "$file"
            else
                git show "$ref:$file" | jq -r '.version // empty'
            fi
            ;;
        *.yaml | *.yml)
            if [[ "$ref" == "WORKTREE" ]]; then
                ruby -e 'require "yaml"; data = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true); puts(data["version"] || "")' "$file"
            else
                git show "$ref:$file" |
                    ruby -e 'require "yaml"; data = YAML.safe_load(STDIN.read, aliases: true); puts(data["version"] || "")'
            fi
            ;;
    esac
}

mapfile -t changed_files < <(
    git diff --cached --name-only --diff-filter=ACMRDTUXB "$base_ref" -- |
        sed '/^$/d'
)

if [[ "${#changed_files[@]}" -eq 0 ]]; then
    echo "has_changes=false" >> "$output_file"
    exit 0
fi

if [[ "${#changed_files[@]}" -gt "$max_files" ]]; then
    echo "AI patch changes ${#changed_files[@]} files; limit is $max_files." >&2
    exit 1
fi

changed_lines="$(
    git diff --cached --numstat "$base_ref" -- |
        awk '
            $1 == "-" || $2 == "-" { binary = 1; next }
            { total += $1 + $2 }
            END {
                if (binary) {
                    print "binary"
                } else {
                    print total + 0
                }
            }
        '
)"

if [[ "$changed_lines" == "binary" ]]; then
    echo "Binary changes are not permitted in an automated AI patch." >&2
    exit 1
fi

if [[ "$changed_lines" -gt "$max_lines" ]]; then
    echo "AI patch changes $changed_lines lines; limit is $max_lines." >&2
    exit 1
fi

disallowed='^(\.github/|\.gitmodules$|CODEOWNERS$|SECURITY\.md$)'
for file in "${changed_files[@]}"; do
    if [[ "$file" =~ $disallowed ]]; then
        echo "Disallowed path changed by AI: $file" >&2
        exit 1
    fi

    if [[ "$file" == */* ]]; then
        top="${file%%/*}"
        if ! git cat-file -e "$base_ref:$top" 2>/dev/null; then
            echo "Creating a new top-level directory is not permitted: $top" >&2
            exit 1
        fi
    fi

    if [[ "$request_category" == "improvement" && -n "$expected_addon" && "$file" != "$expected_addon/"* ]]; then
        echo "Existing add-on improvements may only change '$expected_addon': $file" >&2
        exit 1
    fi

    if [[ -L "$file" ]]; then
        echo "Symbolic links are not permitted in an automated AI patch: $file" >&2
        exit 1
    fi
done

if git diff --cached --unified=0 "$base_ref" -- |
    grep -E '^\+' |
    grep -Ev '^\+\+\+' |
    grep -Eq '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)'; then
    echo "The patch appears to contain a credential or private key." >&2
    exit 1
fi

git diff --cached --check "$base_ref" --

for file in "${changed_files[@]}"; do
    [[ -f "$file" ]] || continue

    case "$file" in
        *.sh)
            bash -n "$file"
            ;;
        *.json)
            jq empty "$file"
            ;;
        *.yaml | *.yml)
            ruby -e 'require "yaml"; YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true)' "$file"
            ;;
    esac
done

declare -A changed_addons=()
for file in "${changed_files[@]}"; do
    top="${file%%/*}"
    [[ "$file" == */* ]] || continue

    if [[ -f "$top/config.yaml" || -f "$top/config.json" ]] ||
        git cat-file -e "$base_ref:$top/config.yaml" 2>/dev/null ||
        git cat-file -e "$base_ref:$top/config.json" 2>/dev/null; then
        changed_addons["$top"]=1
    fi
done

for addon in "${!changed_addons[@]}"; do
    if ! git cat-file -e "$base_ref:$addon/config.yaml" 2>/dev/null &&
        ! git cat-file -e "$base_ref:$addon/config.json" 2>/dev/null; then
        echo "Automated creation of a new add-on is not permitted: $addon" >&2
        exit 1
    fi

    if ! printf '%s\n' "${changed_files[@]}" | grep -Fxq "$addon/CHANGELOG.md"; then
        echo "Changed add-on '$addon' must update CHANGELOG.md." >&2
        exit 1
    fi

    config_changed=false
    for file in "${changed_files[@]}"; do
        if [[ "$file" == "$addon/config.yaml" || "$file" == "$addon/config.json" ]]; then
            config_changed=true
            break
        fi
    done

    if [[ "$config_changed" != true ]]; then
        echo "Changed add-on '$addon' must bump its version in config.yaml or config.json." >&2
        exit 1
    fi

    config_file="$addon/config.yaml"
    [[ -f "$config_file" ]] || config_file="$addon/config.json"

    if [[ ! -f "$config_file" ]]; then
        echo "Automated deletion of add-on '$addon' is not permitted." >&2
        exit 1
    fi

    old_version="$(read_version "$base_ref" "$config_file")"
    new_version="$(read_version WORKTREE "$config_file")"

    if [[ -z "$new_version" || "$old_version" == "$new_version" ]]; then
        echo "Changed add-on '$addon' must change its version value." >&2
        exit 1
    fi
done

echo "Validated ${#changed_files[@]} files and $changed_lines changed lines."
echo "has_changes=true" >> "$output_file"
echo "changed_files=${#changed_files[@]}" >> "$output_file"
echo "changed_lines=$changed_lines" >> "$output_file"
