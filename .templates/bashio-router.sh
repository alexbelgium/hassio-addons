#!/usr/bin/env bash
set -euo pipefail

REAL_BASHIO="/usr/bin/bashio.real"
if [ -x "/usr/bin/bashio" ] && [ ! -x "$REAL_BASHIO" ]; then
  REAL_BASHIO="/usr/bin/bashio"
fi

# ---- Supervisor detection ----

if [ -x "$REAL_BASHIO" ]; then
  # Fast HA detection (s6)
  if [ -S /run/s6/services/supervisor ]; then
    exec "$REAL_BASHIO" "$@"
  fi

  # Fallback ping detection (DNS/API)
  if "$REAL_BASHIO" supervisor ping >/dev/null 2>&1; then
    exec "$REAL_BASHIO" "$@"
  fi
fi

# ---- Standalone fallback ----
# shellcheck disable=SC1091
. /usr/local/lib/bashio-standalone.sh

cmd="${1:-}"; shift || true

case "$cmd" in
  config)
    bashio::config "$@"
    ;;
  log)
    level="${1:-info}"
    shift || true
    fn="bashio::log.${level}"
    if declare -F "$fn" >/dev/null 2>&1; then
      "$fn" "$@"
    else
      bashio::log.info "$@"
    fi
    ;;
  addon)
    sub="${1:-}"
    shift || true
    "bashio::addon.${sub}" "$@" || true
    ;;
  info)
    sub="${1:-}"
    shift || true
    "bashio::info.${sub}" "$@" || true
    ;;
  services)
    bashio::services "$@"
    ;;
  supervisor)
    sub="${1:-}"
    shift || true
    "bashio::supervisor.${sub}" "$@" || true
    ;;
  *)
    echo "bashio router: unsupported command: $cmd" >&2
    exit 1
    ;;
esac
