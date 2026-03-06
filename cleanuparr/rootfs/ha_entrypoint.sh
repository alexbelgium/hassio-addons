#!/bin/bash
# shellcheck shell=bash
set -e

###############################################################################
# Home Assistant Addon entrypoint for Cleanuparr
# The .NET app uses /app/config as its data directory.
# We symlink /app/config → /addon_configs/cleanuparr (HA persistent storage)
# and start ./Cleanuparr directly, bypassing the original /entrypoint.sh
# which would trigger the /config Docker VOLUME mount.
###############################################################################

# ─── Source standalone bashio if available ───────────────────────────────────
if [ -f /usr/local/lib/bashio-standalone.sh ]; then
    # shellcheck disable=SC1091
    source /usr/local/lib/bashio-standalone.sh
fi

# ─── Run cont-init.d scripts (banner, custom_script, ...) ────────────────────
if [ -d /etc/cont-init.d ]; then
    for script in /etc/cont-init.d/*.sh; do
        [ -f "$script" ] || continue
        echo "[Cleanuparr] Running init script: $script"
        bash "$script"
    done
fi

# ─── Setup persistent data directory ─────────────────────────────────────────
HA_DATA_DIR="/addon_configs/cleanuparr"
echo "[Cleanuparr] Setting up data directory: $HA_DATA_DIR"
mkdir -p "$HA_DATA_DIR"

# Symlink /app/config → HA persistent storage
# The .NET app uses /app/config, NOT /config at the filesystem root
if [ -d /app/config ] && [ ! -L /app/config ]; then
    cp -rn /app/config/. "$HA_DATA_DIR/" 2>/dev/null || true
    rm -rf /app/config
fi
ln -sfn "$HA_DATA_DIR" /app/config

chown -R "${PUID:-0}:${PGID:-0}" "$HA_DATA_DIR"

# ─── Start Cleanuparr directly (bypass original /entrypoint.sh) ──────────────
echo "[Cleanuparr] Starting application on port ${HTTP_PORTS:-11011}..."
cd /app
exec ./Cleanuparr
