#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
[[ -f /usr/lib/bashio/bashio.sh ]] && source /usr/lib/bashio/bashio.sh

INPUT_FILE="/data/options.json"
SECRETSFILE="/config/secrets.yaml"
if [[ ! -f "$SECRETSFILE" ]]; then
    SECRETSFILE="/homeassistant/secrets.yaml"
fi

# -------------------------------------------------------------------------------------------------
# Function to export an env var securely and log it (masking secrets)
# -------------------------------------------------------------------------------------------------
export_env_var() {
    local key="$1"
    local value="$2"
    local display_value

    # Validate variable name
    if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        bashio::log.warning "Invalid env var name '$key', skipping"
        return
    fi

    # Mask sensitive keys
    if [[ "$key" =~ (SECRET|TOKEN|PASSWORD|PASS|KEY|API|BEARER|AUTH) ]]; then
        display_value="[HIDDEN]"
    else
        display_value="${value@Q}"
    fi

    # Export
    export "$key"="$value"

    # Log
    if [[ "$display_value" == "[HIDDEN]" ]]; then
        bashio::log.blue "Exporting env var: $key=[HIDDEN]"
    else
        bashio::log.blue "Exporting env var: $key=$display_value"
    fi
}

# -------------------------------------------------------------------------------------------------
# 1. Load variables from options.json
# -------------------------------------------------------------------------------------------------
if [[ -f "$INPUT_FILE" ]]; then
    jq -r '
      (to_entries[] | select(.key != "env_vars") | "\(.key)=\(.value|tostring|@base64)"),
      (.env_vars // [] | to_entries[] | "\(.key)=\(.value|tostring|@base64)")
    ' "$INPUT_FILE" |
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        value_b64="${line#*=}"
        value="$(printf '%s' "$value_b64" | base64 --decode)"
        export_env_var "$key" "$value"
    done
else
    bashio::log.warning "No options.json found at $INPUT_FILE"
fi

# -------------------------------------------------------------------------------------------------
# 2. Load secrets from secrets.yaml
# -------------------------------------------------------------------------------------------------
if [[ -f "$SECRETSFILE" ]]; then
    # Parse YAML: key: value → export key=value
    # Assumes top-level simple secrets (typical HA usage)
    while IFS=: read -r rawkey rawval; do
        key="$(echo "$rawkey" | xargs)"   # trim spaces
        value="$(echo "$rawval" | xargs)" # trim spaces
        [[ -z "$key" || -z "$value" ]] && continue

        # Convert key to uppercase for env var consistency
        # (HA secrets are usually lowercase)
        key_upper="$(echo "$key" | tr '[:lower:]' '[:upper:]')"

        export_env_var "$key_upper" "$value"
    done < <(grep -E '^[^#[:space:]].*:[[:space:]]*.+$' "$SECRETSFILE")
else
    bashio::log.warning "No secrets.yaml found at /config or /homeassistant"
fi
