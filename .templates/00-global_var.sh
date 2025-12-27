#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

if ! bashio::supervisor.ping 2>/dev/null; then
    echo "..."
    exit 0
fi

echo ""
bashio::log.notice "This script converts all addon options to environment variables. Custom variables can be set using env_vars."
bashio::log.notice "Additional informations : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
echo ""

JSONSOURCE="/data/options.json"

# Define secrets location (optional)
SECRETSOURCE=""
if [[ -f /homeassistant/secrets.yaml ]]; then
    SECRETSOURCE="/homeassistant/secrets.yaml"
elif [[ -f /config/secrets.yaml ]]; then
    SECRETSOURCE="/config/secrets.yaml"
fi

# Injection block markers (single block, idempotent)
BLOCK_BEGIN="# --- BEGIN ADDON ENV (generated) ---"
BLOCK_END="# --- END ADDON ENV (generated) ---"

EXPORT_BLOCK_FILE="$(mktemp)"
trap 'rm -f "$EXPORT_BLOCK_FILE"' EXIT

{
    echo "${BLOCK_BEGIN}"
    echo "# Do not edit: generated from ${JSONSOURCE}"
    echo "${BLOCK_END}"
} > "${EXPORT_BLOCK_FILE}"

# Protected variables that should not be overwritten
declare -A PROTECTED_VARS=(
    ["PATH"]=1
    ["HOME"]=1
    ["PWD"]=1
    ["SHLVL"]=1
    ["_"]=1
    ["S6_BEHAVIOR_IF_STAGE2_FAILS"]=1
)

is_valid_env_name() {
    [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

# Quote for shell *code* (for injection into scripts). Keep punctuation intact.
# - single-line => single quotes
# - multi-line  => $'...\n...' (one physical line; safe for injection)
shell_quote_for_code() {
    local s="$1"

    if [[ "$s" == *$'\n'* || "$s" == *$'\r'* || "$s" == *$'\t'* ]]; then
        s="${s//\\/\\\\}"
        s="${s//\'/\\\'}"
        s="${s//$'\n'/\\n}"
        s="${s//$'\r'/\\r}"
        s="${s//$'\t'/\\t}"
        printf "\$'%s'" "$s"
        return 0
    fi

    # single-quote with embedded '"'"' for literal '
    s="${s//\'/\'\"\'\"\' }"
    s="${s% }"
    printf "'%s'" "$s"
}

dotenv_quote() {
    # For /.env and /etc/environment: double quotes + minimal escaping
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    v="${v//$'\n'/\\n}"
    v="${v//$'\r'/\\r}"
    printf '"%s"' "$v"
}

resolve_secret_if_needed() {
    local v="$1"
    local name line

    if [[ "$v" =~ ^[[:space:]]*\!secret[[:space:]]+(.+)[[:space:]]*$ ]]; then
        name="${BASH_REMATCH[1]}"
        name="${name#\"}"; name="${name%\"}"
        name="${name#\'}"; name="${name%\'}"

        if [[ -z "${SECRETSOURCE}" ]]; then
            bashio::log.warning "Homeassistant config not mounted, secrets are not supported"
            printf '%s' "$v"
            return 0
        fi

        # Exact key match at start of line; ignore comments
        line="$(
            awk -v k="$name" '
                /^[[:space:]]*#/ {next}
                $0 ~ "^[[:space:]]*" k ":[[:space:]]*" {
                    sub("^[[:space:]]*" k ":[[:space:]]*", "", $0)
                    print
                    exit
                }
            ' "$SECRETSOURCE"
        )"

        [[ -z "$line" ]] && bashio::exit.nok "Secret '${name}' not found in ${SECRETSOURCE}"
        printf '%s' "$line"
        return 0
    fi

    printf '%s' "$v"
}

append_export_line_for_injection() {
    local key="$1"
    local value="$2"
    local quoted
    quoted="$(shell_quote_for_code "$value")"

    awk -v k="$key" -v q="$quoted" -v end="$BLOCK_END" '
        $0 == end { print "export " k "=" q }
        { print }
    ' "${EXPORT_BLOCK_FILE}" > "${EXPORT_BLOCK_FILE}.tmp"
    mv -f "${EXPORT_BLOCK_FILE}.tmp" "${EXPORT_BLOCK_FILE}"
}

is_shell_run_script() {
    local f="$1"
    local h
    h="$(head -n 1 "$f" 2>/dev/null || true)"

    [[ "$h" =~ ^#! ]] || return 1
    [[ "$h" =~ (sh|bash|with-contenv) ]] && return 0
    return 1
}

inject_block_into_file() {
    local file="$1"
    local tmp
    tmp="$(mktemp)"

    awk -v bfile="${EXPORT_BLOCK_FILE}" -v begin="${BLOCK_BEGIN}" -v end="${BLOCK_END}" '
        function print_block() {
            while ((getline l < bfile) > 0) print l
            close(bfile)
        }
        BEGIN { inblock=0; printed=0 }
        {
            if ($0 == begin) {
                inblock=1
                if (!printed) { print_block(); printed=1 }
                next
            }
            if ($0 == end) { inblock=0; next }
            if (inblock) next

            if (NR == 1) {
                if ($0 ~ /^#!/) {
                    print $0
                    if (!printed) { print_block(); printed=1 }
                    next
                } else {
                    if (!printed) { print_block(); printed=1 }
                    print $0
                    next
                }
            }
            print $0
        }
        END {
            if (!printed) print_block()
        }
    ' "$file" > "$tmp"

    cat "$tmp" > "$file"
    rm -f "$tmp"
}

update_scripts_with_block() {
    local f
    local -A seen=()

    shopt -s nullglob

    # Added /etc/s6-overlay/s6-rc.d/*/run for newer S6 implementation (optional)
    for f in /etc/services.d/*/run /etc/services.d/*/*run* /etc/cont-init.d/*.sh /etc/s6-overlay/s6-rc.d/*/run /*/entrypoint.sh /entrypoint.sh; do
        [[ -f "$f" ]] || continue
        [[ -n "${seen[$f]:-}" ]] && continue
        seen["$f"]=1

        if ! is_shell_run_script "$f"; then
            bashio::log.debug "Skipping non-shell script: $f"
            continue
        fi

        inject_block_into_file "$f"
    done

    shopt -u nullglob
}

export_option() {
    local key="$1"
    local value="$2"

    if [[ -n "${PROTECTED_VARS[$key]:-}" ]]; then
        bashio::log.warning "Skipping protected environment variable: ${key}"
        return 0
    fi

    if ! is_valid_env_name "$key"; then
        bashio::log.warning "Skipping invalid env var name: ${key}"
        return 0
    fi

    value="$(resolve_secret_if_needed "$value")"

    if bashio::config.false "verbose" || [[ "${key,,}" =~ (pass|secret|token|apikey|api_key|private|pwd) ]]; then
        bashio::log.blue "${key}=******"
    else
        bashio::log.blue "${key}=${value}"
    fi

    export "${key}=${value}"

    if [[ -d /var/run/s6/container_environment ]]; then
        printf '%s' "${value}" > "/var/run/s6/container_environment/${key}"
    fi

    echo "${key}=$(dotenv_quote "$value")" >> "/.env" 2>/dev/null || true
    mkdir -p /etc
    echo "${key}=$(dotenv_quote "$value")" >> /etc/environment 2>/dev/null || true

    append_export_line_for_injection "$key" "$value"
}

mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    jtype="$(jq -r --arg k "$KEYS" '.[$k] | type' "$JSONSOURCE")"

    if [[ "$jtype" == "array" ]]; then
        if [[ "$KEYS" == "env_vars" ]]; then
            mapfile -t env_entries < <(jq -c '.env_vars[]?' "$JSONSOURCE")
            for entry in "${env_entries[@]}"; do
                if [[ "$entry" == \{* ]]; then
                    env_name="$(jq -r 'if has("name") and has("value") then .name else empty end' <<<"$entry")"
                    if [[ -n "$env_name" ]]; then
                        env_value="$(jq -r '.value // "" | tostring' <<<"$entry")"
                        export_option "$env_name" "$env_value"
                    else
                        mapfile -t env_keys < <(jq -r 'keys[]' <<<"$entry")
                        for env_key in "${env_keys[@]}"; do
                            env_value="$(jq -r --arg k "$env_key" '.[$k] // "" | tostring' <<<"$entry")"
                            export_option "$env_key" "$env_value"
                        done
                    fi
                else
                    env_pair="$(jq -r '.' <<<"$entry")"
                    if [[ "$env_pair" == *=* ]]; then
                        export_option "${env_pair%%=*}" "${env_pair#*=}"
                    else
                        bashio::log.warning "env_vars entry '$env_pair' is not in KEY=VALUE format, skipping"
                    fi
                fi
            done
        else
            bashio::log.warning "Option '${KEYS}' is an array, skipping"
        fi
    elif [[ "$jtype" == "object" ]]; then
        bashio::log.warning "Option '${KEYS}' is an object, skipping"
    elif [[ "$jtype" == "null" ]]; then
        continue
    else
        VALUE="$(jq -r --arg k "$KEYS" '.[$k] // "" | tostring' "$JSONSOURCE")"
        export_option "$KEYS" "$VALUE"
    fi
done

update_scripts_with_block

################
# Set timezone #
################
set +eu

if [ -n "$TZ" ] && [ -f /etc/localtime ]; then
    if [ -f /usr/share/zoneinfo/"$TZ" ]; then
        echo "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
    fi
fi
