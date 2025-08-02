# /usr/local/lib/bashio-standalone.sh
# shellcheck shell=bash
# Minimal bashio compatibility layer for running Home Assistant add-ons
# as standalone containers (no Supervisor). It overrides common bashio::*
# functions to source config from ENV (and optionally a JSON file).
# Load it conditionally in your entry script when supervisor isn't reachable.

# -------- internals ----------------------------------------------------------

# Whether to emit ANSI colors (disabled if not a TTY)
if [ -t 1 ]; then
  _BASHIO_COLOR=1
else
  _BASHIO_COLOR=0
fi

_bashio_color() {
  # $1=name; returns ANSI sequence or empty
  if [ "$_BASHIO_COLOR" != "1" ]; then return 0; fi
  case "$1" in
    blue)    printf '\033[34m' ;;
    green)   printf '\033[32m' ;;
    yellow)  printf '\033[33m' ;;
    red)     printf '\033[31m' ;;
    magenta) printf '\033[35m' ;;
    reset)   printf '\033[0m'  ;;
  esac
}

_bashio_log() {
  # $1=color name, $2...=msg
  local c="$1"; shift
  local pre; pre="$(_bashio_color "$c")"
  local rst; rst="$(_bashio_color reset)"
  printf '%s%s%s\n' "$pre" "$*" "$rst"
}

# Optional JSON options source (single flat object or nested).
# Set STANDALONE_OPTIONS_JSON to a path (e.g., /data/options.json).
# If jq is present, keys can be fetched as .key or .nested.key
_bashio_json_get() {
  # $1=key (dot.notation). echoes value or empty; returns 0 always
  local key="${1:-}"
  local file="${STANDALONE_OPTIONS_JSON:-}"
  if [ -z "$file" ] || [ ! -f "$file" ] || ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  # jq -r returns "null" for missing; convert to empty
  local val
  val="$(jq -er --arg k "$key" '. as $r | getpath(($k|split("."))) // empty' "$file" 2>/dev/null || true)"
  [ "$val" = "null" ] && val=""
  printf '%s' "$val"
}

# Map a bashio "key" to an env var name.
# Order tried:
#   1) exact as-is
#   2) uppercase exact
#   3) dot->underscore, dash->underscore (upper & lower)
#   4) with prefixes: CFG_, CONFIG_, ADDON_, OPTION_, OPT_
_bashio_env_get() {
  # $1=key
  local key="${1:-}"
  [ -z "$key" ] && return 0

  local variants=()
  variants+=("$key")
  variants+=("$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')")
  variants+=("$(printf '%s' "$key" | tr '.' '_' | tr '-' '_' )")
  variants+=("$(printf '%s' "$key" | tr '.' '_' | tr '-' '_' | tr '[:lower:]' '[:upper:]')")

  local prefixes=(""
                 "CFG_" "CONFIG_" "ADDON_" "OPTION_" "OPT_")

  local v p name
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

# Helper: true/false parsing
_bashio_is_true() {
  # $1=value
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|On) return 0 ;;
    *) return 1 ;;
  esac
}

# Net wait using /dev/tcp (POSIX bash) with a timeout
_bashio_tcp_wait() {
  # $1=host $2=port $3=timeout(s, default 30)
  local host="$1" port="$2" to="${3:-30}"
  local start now
  start="$(date +%s)"
  while :; do
    if exec 3<>"/dev/tcp/${host}/${port}" 2>/dev/null; then
      exec 3>&- 3<&-
      return 0
    fi
    now="$(date +%s)"
    if [ $((now - start)) -ge "$to" ]; then
      return 1
    fi
    sleep 1
  done
}

# -------- logs ---------------------------------------------------------------

bashio::log.blue()    { _bashio_log blue    "$*"; }
bashio::log.green()   { _bashio_log green   "$*"; }
bashio::log.yellow()  { _bashio_log yellow  "$*"; }
bashio::log.red()     { _bashio_log red     "$*"; }
bashio::log.magenta() { _bashio_log magenta "$*"; }

# compatibility aliases often used
bashio::log.info()    { bashio::log.blue    "$@"; }
bashio::log.warning() { bashio::log.yellow  "$@"; }
bashio::log.error()   { bashio::log.red     "$@"; }
bashio::log.debug()   { printf '%s\n' "$*"; }

# -------- supervisor & addon meta -------------------------------------------

# In standalone, "ping" always fails unless forced
bashio::supervisor.ping() {
  if _bashio_is_true "${STANDALONE_FORCE_SUPERVISOR_PING:-}"; then
    return 0
  fi
  return 1
}

# Add-on metadata (use env or sensible defaults)
bashio::addon.name()         { printf '%s' "${ADDON_NAME:-Standalone container}"; }
bashio::addon.description()  { printf '%s' "${ADDON_DESCRIPTION:-Running without Home Assistant Supervisor}"; }
bashio::addon.version()      { printf '%s' "${BUILD_VERSION:-1.0}"; }
bashio::addon.version_latest(){ printf '%s' "${ADDON_VERSION_LATEST:-${BUILD_VERSION:-1.0}}"; }
bashio::addon.update_available() {
  if [ "${ADDON_VERSION_LATEST:-}" != "" ] && [ "${ADDON_VERSION_LATEST:-}" != "${BUILD_VERSION:-}" ]; then
    printf '%s' "true"; return 0
  fi
  printf '%s' "false"
}
bashio::addon.ingress_port()  { printf '%s' "${ADDON_INGRESS_PORT:-}"; }
bashio::addon.ingress_entry() { printf '%s' "${ADDON_INGRESS_ENTRY:-}"; }
bashio::addon.ip_address()    { printf '%s' "${ADDON_IP_ADDRESS:-}"; }

# Ports:
# - numeric arg "8080" -> env PORT_8080 or ADDON_PORT_8080, falling back to the number
# - non-numeric "WEB_PORT" -> resolve as config/env key
bashio::addon.port() {
  local arg="${1:-}"
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    local v
    v="$(_bashio_env_get "PORT_${arg}")"
    [ -z "$v" ] && v="$(_bashio_env_get "ADDON_PORT_${arg}")"
    printf '%s' "${v:-$arg}"
  else
    printf '%s' "$(_bashio_env_get "$arg")"
  fi
}

# -------- system info --------------------------------------------------------

bashio::info.operating_system() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}"
  else
    printf '%s' "Linux"
  fi
}
bashio::info.arch()        { uname -m; }
bashio::info.machine()     { uname -m; }
bashio::info.homeassistant(){ printf '%s' "standalone"; }
bashio::info.supervisor()  { printf '%s' "standalone"; }

# -------- config -------------------------------------------------------------

# Primary getter:
#   1) ENV (several name variants/prefixes)
#   2) JSON file via STANDALONE_OPTIONS_JSON (jq required)
bashio::config() {
  local key="${1:-}"
  local v
  v="$(_bashio_env_get "$key")"
  if [ -z "$v" ]; then
    v="$(_bashio_json_get "$key")"
  fi
  printf '%s' "${v:-}"
}

bashio::config.has_value() { local k="$1"; [ -n "$(bashio::config "$k")" ]; }
bashio::config.true()      { local k="$1"; _bashio_is_true "$(bashio::config "$k")"; }

# Some add-ons call "require.ssl" (noop by default)
bashio::config.require.ssl(){ printf '%s' "${REQUIRE_SSL:-true}"; }

# -------- variables & fs helpers --------------------------------------------

bashio::var.true()      { _bashio_is_true "${1:-}"; }
bashio::var.has_value() { [ -n "${1:-}" ]; }

bashio::fs.directory_exists() { [ -d "$1" ]; }

# -------- network/services ---------------------------------------------------

# Wait for TCP service: bashio::net.wait_for host port [timeout]
bashio::net.wait_for() {
  local host="$1" port="$2" to="${3:-30}"
  _bashio_tcp_wait "$host" "$port" "$to"
}

# Discovery stubs; map to common env names, or JSON:
# Usage patterns seen:
#   bashio::services "mqtt" "host"
#   bashio::services "mysql" "port"
bashio::services() {
  local svc="${1:-}" key="${2:-}"
  [ -z "$svc" ] && return 0
  local upper svc_upper var v
  upper="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
  svc_upper="$(printf '%s' "$svc" | tr '[:lower:]' '[:upper:]')"

  # Common mappings
  case "$svc_upper:$upper" in
    MQTT:HOST)     var="MQTT_HOST" ;;
    MQTT:PORT)     var="MQTT_PORT" ;;
    MQTT:USERNAME) var="MQTT_USER" ;;
    MQTT:PASSWORD) var="MQTT_PASSWORD" ;;
    MQTT:TLS)      var="MQTT_TLS" ;;
    MYSQL:HOST|MARIADB:HOST) var="DB_HOST" ;;
    MYSQL:PORT|MARIADB:PORT) var="DB_PORT" ;;
    MYSQL:USERNAME|MARIADB:USERNAME) var="DB_USER" ;;
    MYSQL:PASSWORD|MARIADB:PASSWORD) var="DB_PASSWORD" ;;
    MYSQL:DATABASE|MARIADB:DATABASE) var="DB_NAME" ;;
    *) var="${svc_upper}_${upper}" ;;
  esac

  v="$(_bashio_env_get "$var")"
  if [ -z "$v" ] && [ -n "${STANDALONE_OPTIONS_JSON:-}" ]; then
    v="$(_bashio_json_get "services.${svc}.${key}")"
    [ -z "$v" ] && v="$(_bashio_json_get "${svc}.${key}")"
  fi
  printf '%s' "${v:-}"
}

# ----- extras for broader compatibility --------------------------------------

# Simple cache (used by add-ons & bashio itself)
_BASHIO_CACHE_DIR="${BASHIO_CACHE_DIR:-/tmp/.bashio}"
mkdir -p "$_BASHIO_CACHE_DIR"

bashio::cache.exists() { [ -f "$_BASHIO_CACHE_DIR/${1}.cache" ]; }
bashio::cache.get()    { [ -f "$_BASHIO_CACHE_DIR/${1}.cache" ] && cat "$_BASHIO_CACHE_DIR/${1}.cache"; }
bashio::cache.set()    { mkdir -p "$_BASHIO_CACHE_DIR"; printf '%s' "${2:-}" > "$_BASHIO_CACHE_DIR/${1}.cache"; }

# Filesystem helpers frequently used
bashio::fs.file_exists()      { [ -f "$1" ]; }
bashio::fs.directory_exists() { [ -d "$1" ]; }  # already defined earlier; keep if present
bashio::fs.file_contains()    { local f="$1" p="$2"; [ -f "$f" ] && grep -q -- "$p" "$f"; }

# jq wrapper (some add-ons call bashio::jq)
bashio::jq() { command -v jq >/dev/null 2>&1 && jq "$@"; }

# env presence (even if empty) used by config.exists
_bashio_env_has() {
  local key="$1" p v name
  [ -z "$key" ] && return 1
  local variants=(
    "$key"
    "$(printf '%s' "$key" | tr '.' '_' )"
    "$(printf '%s' "$key" | tr '.' '_' | tr '[:lower:]' '[:upper:]')"
    "$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
  )
  for v in "${variants[@]}"; do
    for p in "" "CFG_" "CONFIG_" "ADDON_" "OPTION_" "OPT_"; do
      name="${p}${v}"
      if [ -n "${!name+x}" ]; then  # defined, even if empty
        printf '%s' "$name"
        return 0
      fi
    done
  done
  return 1
}

# config.exists : key is present (env or JSON), even if value is empty
bashio::config.exists() {
  local key="$1" file="${STANDALONE_OPTIONS_JSON:-}"
  _bashio_env_has "$key" && return 0
  if [ -n "$file" ] && command -v jq >/dev/null 2>&1; then
    jq -e --arg k "$key" 'haspath(($k|split(".")))' "$file" >/dev/null 2>&1
    return $?
  fi
  return 1
}

# addon.option : write/delete option in JSON when possible; fallback no-op/env
bashio::addon.option() {
  local key="$1" value="${2-__BASHIO_UNSET__}" file="${STANDALONE_OPTIONS_JSON:-}"
  if [ -n "$file" ] && command -v jq >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp)"
    if [ "$value" = "__BASHIO_UNSET__" ]; then
      jq --arg k "$key" 'delpath(($k|split(".")))' "$file" >"$tmp" && mv "$tmp" "$file"
    else
      jq --arg k "$key" --arg v "$value" 'setpath(($k|split(".")); $v)' "$file" >"$tmp" && mv "$tmp" "$file"
    fi
    return 0
  fi
  # Fallbacks: export as env or treat delete as no-op
  if [ "$value" != "__BASHIO_UNSET__" ]; then
    export "$(printf '%s' "$key" | tr '.' '_' | tr '-' '_')"="$value"
  fi
}

# services.available : check if we can resolve at least a host for the service
bashio::services.available() {
  local svc="$1" host; host="$(bashio::services "$svc" "host")"
  [ -n "$host" ]
}

# var helpers
bashio::var.false()     { ! _bashio_is_true "${1:-}"; }
bashio::var.has_value() { [ -n "${1:-}" ]; }  # already present; keep if defined

# exits used by many add-ons
bashio::exit.ok()  { exit 0; }
bashio::exit.nok() { local m="${1:-}"; [ -n "$m" ] && bashio::log.red "$m"; exit 1; }

# core.check : Supervisor does a config check; allow an overridable command
# Set STANDALONE_CORE_CHECK_CMD="hass --script check_config -c /config" to enable
bashio::core.check() {
  if [ -n "${STANDALONE_CORE_CHECK_CMD:-}" ]; then
    eval "$STANDALONE_CORE_CHECK_CMD"
  else
    return 0
  fi
}

# --- improvements & extra shims ---------------------------------------------

# Respect NO_COLOR and dumb terminals
if [ -n "${NO_COLOR:-}" ] || [ "${TERM:-}" = "dumb" ]; then
  _BASHIO_COLOR=0
fi

# net.wait_for: prefer nc if available, fallback to /dev/tcp
_bashio_tcp_wait_nc() {
  # $1=host $2=port $3=timeout(s)
  command -v nc >/dev/null 2>&1 || return 1
  local host="$1" port="$2" to="${3:-30}"
  # BusyBox and OpenBSD nc differ; cover both styles
  nc -z -w "$to" "$host" "$port" 2>/dev/null || nc -z "$host" "$port" 2>/dev/null
}
bashio::net.wait_for() {
  local host="$1" port="$2" to="${3:-30}"
  _bashio_tcp_wait_nc "$host" "$port" "$to" && return 0
  _bashio_tcp_wait "$host" "$port" "$to"
}

# DNS helper: bashio::dns.host <hostname> -> prints an IP (or empty)
bashio::dns.host() {
  local h="${1:-}"
  [ -z "$h" ] && return 1
  if command -v getent >/dev/null 2>&1; then
    getent ahostsv4 "$h" | awk '{print $1; exit}'
  else
    # fallback: try busybox nslookup
    nslookup "$h" 2>/dev/null | awk '/^Address: /{print $2; exit}'
  fi
}

# Hostname
bashio::host.hostname() {
  command -v hostname >/dev/null 2>&1 && hostname || printf '%s' "${HOSTNAME:-unknown}"
}

# Home Assistant token (no Supervisor; read from env or JSON)
bashio::homeassistant.token() {
  local t="${HOMEASSISTANT_TOKEN:-${HASS_TOKEN:-}}"
  if [ -z "$t" ] && [ -n "${STANDALONE_OPTIONS_JSON:-}" ] && command -v jq >/dev/null 2>&1; then
    t="$(jq -er '.homeassistant.token // empty' "$STANDALONE_OPTIONS_JSON" 2>/dev/null || true)"
  fi
  printf '%s' "${t:-}"
}

# config.array:
# Accepts CSV ("a,b,c"), space/newline-separated text, or JSON array ["a","b"].
# Prints one item per line (common pattern in add-ons: `mapfile -t arr < <(bashio::config.array key)`).
bashio::config.array() {
  local key="${1:-}" raw val
  raw="$(bashio::config "$key")"
  [ -z "$raw" ] && return 0

  # JSON array?
  if command -v jq >/dev/null 2>&1 && printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -r '.[]' 2>/dev/null && return 0
  fi

  # CSV -> newline
  if printf '%s' "$raw" | grep -q ','; then
    printf '%s' "$raw" | tr ',' '\n'
    return 0
  fi

  # Already space/newline-separated
  printf '%s\n' "$raw"
}

# Optional: common require.* shims (treat as advisory in standalone)
bashio::config.require.username() { :; }
bashio::config.require.password() { :; }
bashio::config.require.port()     { :; }

# -------- end ----------------------------------------------------------------
