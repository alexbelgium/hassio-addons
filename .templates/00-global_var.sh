#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

# -----------------------------------------------------------------------------
# Guard: only run inside Supervisor-managed add-ons
# -----------------------------------------------------------------------------
if ! bashio::supervisor.ping 2>/dev/null; then
    echo "..."
    exit 0
fi

echo ""
bashio::log.notice "This script converts add-on options (options.json) into environment variables."
bashio::log.notice "Custom variables can be set using the env_vars option."
bashio::log.notice "Additional informations : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
echo ""

# -----------------------------------------------------------------------------
# Inputs / outputs
# -----------------------------------------------------------------------------
JSONSOURCE="/data/options.json"
ENV_FILE="/.env"
ETC_ENV_FILE="/etc/environment"

if [[ ! -f "$JSONSOURCE" ]]; then
    bashio::exit.nok "Missing ${JSONSOURCE}"
fi

if ! command -v jq >/dev/null 2>&1; then
    bashio::exit.nok "jq is required but not found"
fi

mkdir -p /etc
touch "$ETC_ENV_FILE"

# -----------------------------------------------------------------------------
# mktemp helper (safe temp file creation)
# -----------------------------------------------------------------------------
mktemp_safe() {
    local tmpdir="${TMPDIR:-/tmp}"
    mkdir -p "$tmpdir" || return 1

    local tmpfile
    tmpfile="$(mktemp "$tmpdir/tmp.XXXXXXXXXX")" || return 1
    printf '%s\n' "$tmpfile"
}

# -----------------------------------------------------------------------------
# Secrets support:
# - If an option value is "!secret foo", try to resolve it from secrets.yaml
# -----------------------------------------------------------------------------
SECRETSOURCE=""
if [[ -f /homeassistant/secrets.yaml ]]; then
    SECRETSOURCE="/homeassistant/secrets.yaml"
elif [[ -f /config/secrets.yaml ]]; then
    SECRETSOURCE="/config/secrets.yaml"
fi

# -----------------------------------------------------------------------------
# Injection block markers:
# 1) EXPORT_BLOCK_*: injected into run scripts / bashrc so services inherit vars
# 2) FILE_BLOCK_*  : written into /.env and /etc/environment (idempotent)
# -----------------------------------------------------------------------------
BLOCK_BEGIN="# --- BEGIN ADDON ENV (generated) ---"
BLOCK_END="# --- END ADDON ENV (generated) ---"

FILE_BLOCK_BEGIN="# --- BEGIN ADDON ENV FILE (generated) ---"
FILE_BLOCK_END="# --- END ADDON ENV FILE (generated) ---"

EXPORT_BLOCK_FILE="$(mktemp_safe)"
ENV_KV_FILE="$(mktemp_safe)"
trap 'rm -f "$EXPORT_BLOCK_FILE" "$ENV_KV_FILE"' EXIT

{
    echo "${BLOCK_BEGIN}"
    echo "# Do not edit: generated from ${JSONSOURCE}"
    echo "${BLOCK_END}"
} > "${EXPORT_BLOCK_FILE}"

# -----------------------------------------------------------------------------
# Protected variables that should not be overwritten
# -----------------------------------------------------------------------------
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
    # Insert one export line right before BLOCK_END in EXPORT_BLOCK_FILE.
    # (kept as-is to preserve behavior; safe and idempotent block replacement)
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
    # Inject/replace the generated export block in a target script:
    # - If the block exists: replace it.
    # - If not: insert it right after the shebang (if present), else at top.
    local file="$1"
    local tmp
    tmp="$(mktemp_safe)"

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
    # Inject the export block into common service scripts and entrypoints.
    local f
    local -A seen=()

    shopt -s nullglob

    # Includes legacy and newer s6 locations
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

replace_block_in_file() {
    # Replace (or add) a generated block inside a plain text file.
    # Used for /.env and /etc/environment to prevent infinite append growth.
    local file="$1"
    local begin="$2"
    local end="$3"
    local content_file="$4"
    local tmp

    tmp="$(mktemp_safe)"

    if [[ ! -f "$file" ]]; then
        touch "$file"
    fi

    awk -v bfile="$content_file" -v begin="$begin" -v end="$end" '
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
            print $0
        }
        END { if (!printed) print_block() }
    ' "$file" > "$tmp"

    cat "$tmp" > "$file"
    rm -f "$tmp"
}

export_option() {
    # Core exporter:
    # - validates key
    # - resolves secrets
    # - logs (redacted if sensitive unless verbose)
    # - exports into current process
    # - exports into s6 environment
    # - queues key/value for generated /.env and /etc/environment blocks
    # - adds export into injection block for scripts
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

    # Export for s6 services (preferred way)
    if [[ -d /var/run/s6/container_environment ]]; then
        printf '%s' "${value}" > "/var/run/s6/container_environment/${key}"
    fi

    # Queue dotenv-style line for writing once (idempotent file update later)
    echo "${key}=$(dotenv_quote "$value")" >> "$ENV_KV_FILE" 2>/dev/null || true

    # Ensure scripts/services also see it (block injection)
    append_export_line_for_injection "$key" "$value"
}

# -----------------------------------------------------------------------------
# One jq pass emits normalized key/value pairs:
# - exports all scalar top-level options (strings/numbers/bools)
# - skips objects/arrays (except env_vars)
# - supports env_vars formats:
#   1) [{name:"FOO", value:"bar"}, ...]
#   2) [{FOO:"bar", BAZ:"qux"}, ...]
#   3) ["FOO=bar", ...]  (value may contain '=')
# -----------------------------------------------------------------------------
while IFS= read -r -d $'\0' key && IFS= read -r value; do
    export_option "$key" "$value"
done < <(
    jq -r '
        def emit(k; v): "\((k|tostring))\u0000\((v|tostring))";

        # --- 1) env_vars[] ---
        ( .env_vars? // [] )[] as $ev
        | if ($ev | type) == "object" then
              if ($ev | has("name") and has("value")) then
                  emit($ev.name; ($ev.value // ""))
              else
                  ($ev | to_entries[] | emit(.key; (.value // "")))
              end
          else
              ($ev | tostring) as $s
              | if ($s | test("^[^=]+=")) then
                    ($s | capture("^(?<k>[^=]+)=(?<v>.*)$")) as $m
                    | emit($m.k; $m.v)
                else empty end
          end
        ,
        # --- 2) top-level scalars excluding env_vars ---
        to_entries[]
        | select(.key != "env_vars")
        | select((.value|type) != "array" and (.value|type) != "object" and (.value|type) != "null")
        | emit(.key; .value)
    ' "$JSONSOURCE"
)

# -----------------------------------------------------------------------------
# Write /.env and /etc/environment in an idempotent way (no infinite appends)
# -----------------------------------------------------------------------------
# Ensure /.env has a header (only if missing)
if [[ ! -f "$ENV_FILE" ]]; then
    printf '# Generated by 00-global_var.sh from %s\n' "$JSONSOURCE" > "$ENV_FILE"
fi

ENV_FILE_BLOCK="$(mktemp_safe)"
trap 'rm -f "$EXPORT_BLOCK_FILE" "$ENV_KV_FILE" "$ENV_FILE_BLOCK"' EXIT

{
    echo "${FILE_BLOCK_BEGIN}"
    echo "# Do not edit: generated from ${JSONSOURCE}"
    cat "$ENV_KV_FILE" 2>/dev/null || true
    echo "${FILE_BLOCK_END}"
} > "$ENV_FILE_BLOCK"

replace_block_in_file "$ENV_FILE" "$FILE_BLOCK_BEGIN" "$FILE_BLOCK_END" "$ENV_FILE_BLOCK"
replace_block_in_file "$ETC_ENV_FILE" "$FILE_BLOCK_BEGIN" "$FILE_BLOCK_END" "$ENV_FILE_BLOCK"

# -----------------------------------------------------------------------------
# Inject generated export block into service scripts and interactive shells
# -----------------------------------------------------------------------------
update_scripts_with_block

# System-wide interactive bash shells
touch "/etc/bash.bashrc"
inject_block_into_file "/etc/bash.bashrc"

# Common per-user interactive bash shell config (more standard than bash.bashrc)
if [[ -n "${HOME:-}" ]]; then
    mkdir -p "$HOME"
    touch "$HOME/.bashrc"
    inject_block_into_file "$HOME/.bashrc"

    # Kept for compatibility with images that use this non-standard name
    touch "$HOME/bash.bashrc"
    inject_block_into_file "$HOME/bash.bashrc"
fi

# -----------------------------------------------------------------------------
# Set timezone (kept identical in behavior)
# -----------------------------------------------------------------------------
set +eu

if [ -n "$TZ" ] && [ -f /etc/localtime ]; then
    if [ -f /usr/share/zoneinfo/"$TZ" ]; then
        echo "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
    fi
fi
