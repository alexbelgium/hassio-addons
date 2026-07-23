#!/usr/bin/env bash
set -euo pipefail

mapping_file="${1:-.github/addon_submitters.json}"
output_file="${GITHUB_OUTPUT:-/dev/stdout}"

if [[ ! -f "$mapping_file" ]]; then
    echo "Mapping file not found: $mapping_file" >&2
    exit 1
fi

normalize() {
    tr '[:upper:]' '[:lower:]' |
        sed -E 's/[^a-z0-9]+/ /g; s/^ +//; s/ +$//; s/ +/ /g'
}

text="$(printf '%s %s' "${ISSUE_TITLE:-}" "${ISSUE_BODY:-}" | normalize)"
text=" $text "
matches='[]'

while IFS= read -r addon; do
    [[ -z "$addon" ]] && continue

    submitter="$(jq -r --arg addon "$addon" '.[$addon] // empty' "$mapping_file")"
    [[ -z "$submitter" ]] && continue

    normalized_addon="$(printf '%s' "$addon" | normalize)"
    [[ -z "$normalized_addon" ]] && continue

    if [[ "$text" == *" $normalized_addon "* ]]; then
        matches="$(
            jq -c \
                --arg addon "$addon" \
                --arg submitter "$submitter" \
                '. + [{addon: $addon, submitter: $submitter}]' <<< "$matches"
        )"
    fi
done < <(jq -r 'keys[]' "$mapping_file")

matched=false
addon=''
submitter=''

if [[ "$(jq 'length' <<< "$matches")" -gt 0 ]]; then
    matched=true
    addon="$(jq -r '.[0].addon' <<< "$matches")"
    submitter="$(jq -r '.[0].submitter' <<< "$matches")"
fi

{
    echo "matched=$matched"
    echo "addon=$addon"
    echo "submitter=$submitter"
    echo "matches_json=$matches"
} >> "$output_file"
