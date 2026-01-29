# /usr/local/lib/bashio-standalone.sh
# shellcheck shell=bash
# Minimal bashio compatibility layer for running Home Assistant add-ons
# in standalone containers (no Supervisor).

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------

: "${STANDALONE_OPTIONS_JSON:=/data/options.json}"
: "${BASHIO_CACHE_DIR:=/tmp/.bashio}"

# -----------------------------------------------------------------------------
# Color handling
# -----------------------------------------------------------------------------

_BASHIO_COLOR=1
[ ! -t 1 ] && _BASHIO_COLOR=0
[ -n "${NO_COLOR:-}" ] && _BASHIO_COLOR=0
[ "${TERM:-}" = "dumb" ] && _BASHIO_COLOR=0

_bashio_color() {
    [ "$_BASHIO_COLOR" = "1" ] || return 0
    case "$1" in
        blue) printf '\033[34m' ;;
        green) printf '\033[32m' ;;
        yellow) printf '\033[33m' ;;
        red) printf '\033[31m' ;;
        magenta) printf '\033[35m' ;;
        reset) printf '\033[0m' ;;
    esac
}

_bashio_log() {
    local c="$1"; shift
    printf '%s%s%s\n' "$(_bashio_color "$c")" "$*" "$(_bashio_color reset)"
}

# -----------------------------------------------------------------------------
# JSON access (jq optional)
# -----------------------------------------------------------------------------

_bashio_json_get() {
    local key="$1" file="$STANDALONE_OPTIONS_JSON"
    [ -f "$file" ] || return 0
    command -v jq >/dev/null 2>&1 || return 0

    jq -er --arg k "$key" '
      getpath(($k|split("."))) // empty
    ' "$file" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# ENV mapping helper
# -----------------------------------------------------------------------------

_bashio_env_get() {
    local key="$1"
    [ -z "$key" ] && return 0

    local v p name
    local variants=(
        "$key"
        "${key^^}"
        "${key//./_}"
        "${key//./_}"
    )
    variants+=("${variants[2]^^}")

    local prefixes=("" "CFG_" "CONFIG_" "ADDON_" "OPTION_" "OPT_")

    for v in "${variants[@]}"; do
        for p in "${prefixes[@]}"; do
            name="${p}${v}"
            if [ -n "${!name+x}" ]; then
                printf '%s' "${!name}"
                return 0
            fi
        done
    done
}

# -----------------------------------------------------------------------------
# Boolean parsing
# -----------------------------------------------------------------------------

_bashio_is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Logging API
# -----------------------------------------------------------------------------

bashio::log.blue()    { _bashio_log blue "$*"; }
bashio::log.green()   { _bashio_log green "$*"; }
bashio::log.yellow()  { _bashio_log yellow "$*"; }
bashio::log.red()     { _bashio_log red "$*"; }
bashio::log.magenta() { _bashio_log magenta "$*"; }

bashio::log.info()    { bashio::log.blue "$@"; }
bashio::log.warning() { bashio::log.yellow "$@"; }
bashio::log.error()   { bashio::log.red "$@"; }
bashio::log.debug()   { printf '%s\n' "$*"; }

# -----------------------------------------------------------------------------
# Supervisor shim
# -----------------------------------------------------------------------------

bashio::supervisor.ping() {
    _bashio_is_true "${STANDALONE_FORCE_SUPERVISOR_PING:-}" && return 0
    return 1
}

# -----------------------------------------------------------------------------
# Addon metadata
# -----------------------------------------------------------------------------

bashio::addon.name()              { printf '%s' "${ADDON_NAME:-Standalone container}"; }
bashio::addon.description()       { printf '%s' "${ADDON_DESCRIPTION:-Standalone mode}"; }
bashio::addon.version()            { printf '%s' "${BUILD_VERSION:-1.0}"; }
bashio::addon.version_latest()     { printf '%s' "${ADDON_VERSION_LATEST:-${BUILD_VERSION:-1.0}}"; }
bashio::addon.update_available()   { [ "${ADDON_VERSION_LATEST:-}" != "${BUILD_VERSION:-}" ] && echo true || echo false; }
bashio::addon.ingress_port()        { printf '%s' "${ADDON_INGRESS_PORT:-}"; }
bashio::addon.ingress_entry()       { printf '%s' "${ADDON_INGRESS_ENTRY:-}"; }
bashio::addon.ip_address()          { printf '%s' "${ADDON_IP_ADDRESS:-}"; }

bashio::addon.port() {
    local arg="$1"
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        printf '%s' "$(_bashio_env_get "PORT_${arg}" || _bashio_env_get "ADDON_PORT_${arg}" || echo "$arg")"
    else
        printf '%s' "$(_bashio_env_get "$arg")"
    fi
}

# -----------------------------------------------------------------------------
# System info
# -----------------------------------------------------------------------------

bashio::info.operating_system() { . /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}"; }
bashio::info.arch()             { uname -m; }
bashio::info.machine()          { uname -m; }
bashio::info.homeassistant()    { echo "standalone"; }
bashio::info.supervisor()       { echo "standalone"; }

# -----------------------------------------------------------------------------
# Config API
# -----------------------------------------------------------------------------

bashio::config() {
    local key="$1"
    local v="$(_bashio_env_get "$key")"
    [ -z "$v" ] && v="$(_bashio_json_get "$key")"
    printf '%s' "${v:-}"
}

bashio::config.has_value() { [ -n "$(bashio::config "$1")" ]; }
bashio::config.true()      { _bashio_is_true "$(bashio::config "$1")"; }
bashio::config.require.ssl() { echo "${REQUIRE_SSL:-true}"; }

# -----------------------------------------------------------------------------
# Filesystem helpers
# -----------------------------------------------------------------------------

bashio::fs.file_exists()      { [ -f "$1" ]; }
bashio::fs.directory_exists() { [ -d "$1" ]; }
bashio::fs.file_contains()    { grep -q -- "$2" "$1" 2>/dev/null; }

# -----------------------------------------------------------------------------
# Network helpers
# -----------------------------------------------------------------------------

bashio::net.wait_for() {
    local host="$1" port="$2" to="${3:-30}"
    command -v nc >/dev/null 2>&1 && nc -z -w "$to" "$host" "$port" && return 0
    local start=$(date +%s)
    while ! exec 3<>"/dev/tcp/$host/$port" 2>/dev/null; do
        (( $(date +%s) - start >= to )) && return 1
        sleep 1
    done
    exec 3>&- 3<&-
}

# -----------------------------------------------------------------------------
# Services discovery shim
# -----------------------------------------------------------------------------

bashio::services() {
    local svc="$1" key="$2"
    local env="${svc^^}_${key^^}"
    _bashio_env_get "$env" || _bashio_json_get "services.$svc.$key"
}

bashio::services.available() { [ -n "$(bashio::services "$1" host)" ]; }

# -----------------------------------------------------------------------------
# Cache
# -----------------------------------------------------------------------------

mkdir -p "$BASHIO_CACHE_DIR"
bashio::cache.exists() { [ -f "$BASHIO_CACHE_DIR/$1.cache" ]; }
bashio::cache.get()    { cat "$BASHIO_CACHE_DIR/$1.cache" 2>/dev/null; }
bashio::cache.set()    { echo "$2" > "$BASHIO_CACHE_DIR/$1.cache"; }

# -----------------------------------------------------------------------------
# Arrays
# -----------------------------------------------------------------------------

bashio::config.array() {
    local raw
    raw="$(bashio::config "$1")"
    [ -z "$raw" ] && return 0

    if command -v jq >/dev/null 2>&1 && echo "$raw" | jq -e . >/dev/null 2>&1; then
        echo "$raw" | jq -r '.[]'
    elif [[ "$raw" == *","* ]]; then
        tr ',' '\n' <<<"$raw"
    else
        printf '%s\n' $raw
    fi
}

# -----------------------------------------------------------------------------
# Home Assistant token
# -----------------------------------------------------------------------------

bashio::homeassistant.token() {
    echo "${HOMEASSISTANT_TOKEN:-${HASS_TOKEN:-$(_bashio_json_get 'homeassistant.token')}}"
}

# -----------------------------------------------------------------------------
# Exit helpers
# -----------------------------------------------------------------------------

bashio::exit.ok()  { exit 0; }
bashio::exit.nok() { bashio::log.red "$1"; exit 1; }

# -----------------------------------------------------------------------------
# Core config check shim
# -----------------------------------------------------------------------------

bashio::core.check() {
    [ -n "${STANDALONE_CORE_CHECK_CMD:-}" ] && eval "$STANDALONE_CORE_CHECK_CMD" || true
}
