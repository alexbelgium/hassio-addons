#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

DATA_DIR="/app/data"
CFG_DIR="${DATA_DIR}/config"
SETTINGS="${CFG_DIR}/user_settings.json"

if [ -f "$SETTINGS" ]; then
  if ! grep -q 'detection' "$SETTINGS"; then
    bak="${SETTINGS}.bak"
    [ -e "$bak" ] && bak="${SETTINGS}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    mv -f -- "$SETTINGS" "$bak"
    echo "WARNING: Erroneous file detected: '$SETTINGS' did not contain 'detection' and was renamed to '$bak'." >&2
  fi
fi
