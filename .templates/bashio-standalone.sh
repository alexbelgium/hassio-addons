#!/usr/bin/env bash
# /usr/local/lib/bashio-standalone.sh
# shellcheck shell=bash
#
# Minimal bashio compatibility layer for running Home Assistant add-ons
# in standalone containers (no Supervisor).
#
# Goals:
# - Keep add-ons that depend on bashio from crashing outside HA Supervisor
# - Prefer ENV, optionally read /data/options.json (jq required)
# - Provide common bashio::* functions seen across add-ons
#
# Usage (typical):
#   if ! bashio::supervisor.ping 2>/dev/null; then
#     # standalone behavior...
#   fi
#   source /usr/local/lib/bashio-standalone.sh

set -u

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
  case "${1:-}" in
    blue)    printf '\033[34m' ;;
    green)   printf '\033[32m' ;;
    yellow)  printf '\033[33m' ;;
    red)     printf '\033[31m' ;;
    magenta) printf '\033[35m' ;;
    reset)   printf '\033[0m'  ;;
    *)       printf '' ;;
  esac
}

_bashio_log() {
  local c="${1:-}"; shift || true
  printf '%s%s%s\n' "$(_bashio_color "$c")" "$*" "$(_bashio_color reset)"
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
_bashio_is_true() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON|On) return 0 ;;
    *) return 1 ;;
  esac
}

# ENV mapping helper:
# tries variants + prefixes and prints the value if env var is defined (even empty),
# returning 0 when found, 1 when not found.
_bashio_env_get() {
  local key="${1:-}"
  [ -n "$key" ] || return 1

  local norm norm_uc raw_uc
  norm="$(printf '%s' "$key" | tr '.-' '__')"
  norm_uc="$(printf '%s' "$norm" | tr '[:lower:]' '[:upper:]')"
  raw_uc="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"

  local variants=(
    "$key"
    "$raw_uc"
    "$norm"
    "$norm_uc"
  )

  local prefixes=("" "CFG_" "CONFIG_" "ADDON_" "OPTION_" "OPT_")

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

  return 1
}

# env presence (even if empty) used by config.exists
_bashio_env_has() {
  local key="${1:-}"
  [ -n "$key" ] || return 1
  _bashio_env_get "$key" >/dev/null 2>&1
}

# JSON options source (jq required). Prints value or empty; returns 0 always.
_bashio_json_get() {
  local key="${1:-}"
  local file="${STANDALONE_OPTIONS_JSON:-}"

  [ -n "$key" ] || return 0
  [ -n "$file" ] || return 0
  [ -f "$file" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  # getpath(split(".")) supports nested access; missing => empty
  jq -er --arg k "$key" 'getpath(($k|split("."))) // empty' "$file" 2>/dev/null || true
}

# Net wait using /dev/tcp with a timeout
_bashio_tcp_wait() {
  local host="${1:-}" port="${2:-}" to="${3:-30}"
  [ -n "$host" ] && [ -n "$port" ] || return 1

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

# Prefer nc if present, fallback to /dev/tcp
_bashio_tcp_wait_nc() {
  command -v nc >/dev/null 2>&1 || return 1
  local host="${1:-}" port="${2:-}" to="${3:-30}"
  # BusyBox and OpenBSD nc differ; cover both styles
  nc -z -w "$to" "$host" "$port" 2>/dev/null || nc -z "$host" "$port" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Logging API
# -----------------------------------------------------------------------------
bashio::log.blue()    { _bashio_log blue    "$*"; }
bashio::log.green()   { _bashio_log green   "$*"; }
bashio::log.yellow()  { _bashio_log yellow  "$*"; }
bashio::log.red()     { _bashio_log red     "$*"; }
bashio::log.magenta() { _bashio_log magenta "$*"; }

# Common aliases
bashio::log.info()    { bashio::log.blue   "$@"; }
bashio::log.warning() { bashio::log.yellow "$@"; }
bashio::log.error()   { bashio::log.red    "$@"; }
bashio::log.debug()   { printf '%s\n' "$*"; }

# -----------------------------------------------------------------------------
# Supervisor shim
# -----------------------------------------------------------------------------
bashio::supervisor.ping() {
  _bashio_is_true "${STANDALONE_FORCE_SUPERVISOR_PING:-}" && return 0
  return 1
}

# -----------------------------------------------------------------------------
# Add-on metadata
# -----------------------------------------------------------------------------
bashio::addon.name()         { printf '%s' "${ADDON_NAME:-Standalone container}"; }
bashio::addon.description()  { printf '%s' "${ADDON_DESCRIPTION:-Running without Home Assistant Supervisor}"; }
bashio::addon.version()      { printf '%s' "${BUILD_VERSION:-1.0}"; }
bashio::addon.version_latest(){ printf '%s' "${ADDON_VERSION_LATEST:-${BUILD_VERSION:-1.0}}"; }

bashio::addon.update_available() {
  if [ -n "${ADDON_VERSION_LATEST:-}" ] && [ "${ADDON_VERSION_LATEST:-}" != "${BUILD_VERSION:-}" ]; then
    printf '%s' "true"
  else
    printf '%s' "false"
  fi
}

bashio::addon.ingress_port()  { printf '%s' "${ADDON_INGRESS_PORT:-}"; }
bashio::addon.ingress_entry() { printf '%s' "${ADDON_INGRESS_ENTRY:-}"; }
bashio::addon.ip_address()    { printf '%s' "${ADDON_IP_ADDRESS:-}"; }

# Ports:
# - numeric arg "8080" -> env PORT_8080 or ADDON_PORT_8080, fallback to the number
# - non-numeric "WEB_PORT" -> resolve as config/env key
bashio::addon.port() {
  local arg="${1:-}"
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    local v=""
    v="$(_bashio_env_get "PORT_${arg}" 2>/dev/null || true)"
    [ -z "$v" ] && v="$(_bashio_env_get "ADDON_PORT_${arg}" 2>/dev/null || true)"
    printf '%s' "${v:-$arg}"
  else
    printf '%s' "$(_bashio_env_get "$arg" 2>/dev/null || true)"
  fi
}

# addon.option : write/delete option in JSON when possible; fallback export env
bashio::addon.option() {
  local key="${1:-}" value="${2-__BASHIO_UNSET__}" file="${STANDALONE_OPTIONS_JSON:-}"
  [ -n "$key" ] || return 0

  if [ -n "$file" ] && [ -f "$file" ] && command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    if [ "$value" = "__BASHIO_UNSET__" ]; then
      jq --arg k "$key" 'delpath(($k|split(".")))' "$file" >"$tmp" && mv "$tmp" "$file"
    else
      jq --arg k "$key" --arg v "$value" 'setpath(($k|split(".")); $v)' "$file" >"$tmp" && mv "$tmp" "$file"
    fi
    return 0
  fi

  # Fallback: export as env (dot/dash -> underscore). Delete becomes no-op.
  if [ "$value" != "__BASHIO_UNSET__" ]; then
    export "$(printf '%s' "$key" | tr '.-' '__')"="$value"
  fi
}

# -----------------------------------------------------------------------------
# System info
# -----------------------------------------------------------------------------
bashio::info.operating_system() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}"
  else
    printf '%s' "Linux"
  fi
}
bashio::info.arch()         { uname -m; }
bashio::info.machine()      { uname -m; }
bashio::info.homeassistant(){ printf '%s' "standalone"; }
bashio::info.supervisor()  { printf '%s' "standalone"; }

# -----------------------------------------------------------------------------
# Config API
# -----------------------------------------------------------------------------
bashio::config() {
  local key="${1:-}"
  [ -n "$key" ] || { printf '%s' ""; return 0; }

  local v=""
  if _bashio_env_get "$key" >/dev/null 2>&1; then
    v="$(_bashio_env_get "$key" 2>/dev/null || true)"
  fi
  [ -z "$v" ] && v="$(_bashio_json_get "$key")"
  printf '%s' "${v:-}"
}

bashio::config.has_value() { [ -n "$(bashio::config "$1")" ]; }

bashio::config.true() {
  _bashio_is_true "$(bashio::config "$1")"
}

# config.exists : key is present (env or JSON), even if value is empty
bashio::config.exists() {
  local key="${1:-}" file="${STANDALONE_OPTIONS_JSON:-}"
  [ -n "$key" ] || return 1

  if _bashio_env_has "$key"; then
    return 0
  fi

  if [ -n "$file" ] && [ -f "$file" ] && command -v jq >/dev/null 2>&1; then
    jq -e --arg k "$key" 'haspath(($k|split(".")))' "$file" >/dev/null 2>&1
    return $?
  fi

  return 1
}

# Common "require.*" shims (advisory/no-op in standalone)
bashio::config.require.ssl()      { printf '%s' "${REQUIRE_SSL:-true}"; }
bashio::config.require.username() { :; }
bashio::config.require.password() { :; }
bashio::config.require.port()     { :; }

# config.array:
# Accepts CSV ("a,b,c"), space/newline-separated text, or JSON array ["a","b"].
# Prints one item per line.
bashio::config.array() {
  local key="${1:-}" raw
  raw="$(bashio::config "$key")"
  [ -n "$raw" ] || return 0

  if command -v jq >/dev/null 2>&1 && printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -r '.[]' 2>/dev/null && return 0
  fi

  if printf '%s' "$raw" | grep -q ','; then
    printf '%s' "$raw" | tr ',' '\n'
    return 0
  fi

  printf '%s\n' "$raw"
}

# -----------------------------------------------------------------------------
# var helpers
# -----------------------------------------------------------------------------
bashio::var.true()      { _bashio_is_true "${1:-}"; }
bashio::var.false()     { ! _bashio_is_true "${1:-}"; }
bashio::var.has_value() { [ -n "${1:-}" ]; }

# -----------------------------------------------------------------------------
# Filesystem helpers
# -----------------------------------------------------------------------------
bashio::fs.file_exists()      { [ -f "${1:-}" ]; }
bashio::fs.directory_exists() { [ -d "${1:-}" ]; }
bashio::fs.file_contains() {
  local f="${1:-}" p="${2:-}"
  [ -f "$f" ] && grep -q -- "$p" "$f" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Network helpers
# -----------------------------------------------------------------------------
# Wait for TCP service: bashio::net.wait_for host port [timeout]
bashio::net.wait_for() {
  local host="${1:-}" port="${2:-}" to="${3:-30}"
  _bashio_tcp_wait_nc "$host" "$port" "$to" && return 0
  _bashio_tcp_wait "$host" "$port" "$to"
}

# DNS helper: bashio::dns.host <hostname> -> prints an IP (or empty)
bashio::dns.host() {
  local h="${1:-}"
  [ -n "$h" ] || return 1
  if command -v getent >/dev/null 2>&1; then
    getent ahostsv4 "$h" | awk '{print $1; exit}'
  else
    nslookup "$h" 2>/dev/null | awk '/^Address: /{print $2; exit}'
  fi
}

# Hostname
bashio::host.hostname() {
  command -v hostname >/dev/null 2>&1 && hostname || printf '%s' "${HOSTNAME:-unknown}"
}

# -----------------------------------------------------------------------------
# Services discovery shim
# -----------------------------------------------------------------------------
# Usage:
#   bashio::services "mqtt" "host"
#   bashio::services.available "mqtt"
bashio::services() {
  local svc="${1:-}" key="${2:-}"
  [ -n "$svc" ] && [ -n "$key" ] || { printf '%s' ""; return 0; }

  local upper svc_upper var v=""
  upper="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
  svc_upper="$(printf '%s' "$svc" | tr '[:lower:]' '[:upper:]')"

  # Common mappings
  case "$svc_upper:$upper" in
    MQTT:HOST)     var="MQTT_HOST" ;;
    MQTT:PORT)     var="MQTT_PORT" ;;
    MQTT:USERNAME) var="MQTT_USER" ;;
    MQTT:PASSWORD) var="MQTT_PASSWORD" ;;
    MQTT:TLS)      var="MQTT_TLS" ;;
    MYSQL:HOST|MARIADB:HOST)         var="DB_HOST" ;;
    MYSQL:PORT|MARIADB:PORT)         var="DB_PORT" ;;
    MYSQL:USERNAME|MARIADB:USERNAME) var="DB_USER" ;;
    MYSQL:PASSWORD|MARIADB:PASSWORD) var="DB_PASSWORD" ;;
    MYSQL:DATABASE|MARIADB:DATABASE) var="DB_NAME" ;;
    *) var="${svc_upper}_${upper}" ;;
  esac

  v="$(_bashio_env_get "$var" 2>/dev/null || true)"
  if [ -z "$v" ]; then
    v="$(_bashio_json_get "services.${svc}.${key}")"
    [ -z "$v" ] && v="$(_bashio_json_get "${svc}.${key}")"
  fi
  printf '%s' "${v:-}"
}

bashio::services.available() {
  local svc="${1:-}" host
  host="$(bashio::services "$svc" "host")"
  [ -n "$host" ]
}

# -----------------------------------------------------------------------------
# Cache
# -----------------------------------------------------------------------------
mkdir -p "$BASHIO_CACHE_DIR"
bashio::cache.exists() { [ -f "$BASHIO_CACHE_DIR/${1}.cache" ]; }
bashio::cache.get()    { [ -f "$BASHIO_CACHE_DIR/${1}.cache" ] && cat "$BASHIO_CACHE_DIR/${1}.cache"; }
bashio::cache.set()    { printf '%s' "${2:-}" > "$BASHIO_CACHE_DIR/${1}.cache"; }

# -----------------------------------------------------------------------------
# jq wrapper (some add-ons call bashio::jq)
# -----------------------------------------------------------------------------
bashio::jq() { command -v jq >/dev/null 2>&1 && jq "$@"; }

# -----------------------------------------------------------------------------
# Home Assistant token
# -----------------------------------------------------------------------------
bashio::homeassistant.token() {
  local t="${HOMEASSISTANT_TOKEN:-${HASS_TOKEN:-}}"
  if [ -z "$t" ] && [ -n "${STANDALONE_OPTIONS_JSON:-}" ] && [ -f "${STANDALONE_OPTIONS_JSON:-}" ] && command -v jq >/dev/null 2>&1; then
    t="$(jq -er '.homeassistant.token // empty' "$STANDALONE_OPTIONS_JSON" 2>/dev/null || true)"
  fi
  printf '%s' "${t:-}"
}

# -----------------------------------------------------------------------------
# Exit helpers
# -----------------------------------------------------------------------------
bashio::exit.ok()  { exit 0; }
bashio::exit.nok() { local m="${1:-}"; [ -n "$m" ] && bashio::log.red "$m"; exit 1; }

# -----------------------------------------------------------------------------
# Core config check shim
# -----------------------------------------------------------------------------
# Set STANDALONE_CORE_CHECK_CMD="hass --script check_config -c /config" to enable
bashio::core.check() {
  if [ -n "${STANDALONE_CORE_CHECK_CMD:-}" ]; then
    eval "$STANDALONE_CORE_CHECK_CMD"
  else
    return 0
  fi
}
