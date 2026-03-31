#!/bin/bash
# shellcheck shell=bash
set -e

###############################################################################
# Home Assistant Addon entrypoint for Maintainerr
# Runs cont-init.d scripts then drops privileges and starts the app.
###############################################################################

# ─── Source standalone bashio if available ───────────────────────────────────
if [ -f /usr/local/lib/bashio-standalone.sh ]; then
    # shellcheck disable=SC1091
    source /usr/local/lib/bashio-standalone.sh
fi

# ─── Run cont-init.d scripts ─────────────────────────────────────────────────
if [ -d /etc/cont-init.d ]; then
    for script in /etc/cont-init.d/*.sh; do
        [ -f "$script" ] || continue
        echo "[Maintainerr] Running init script: $script"
        # Use bash directly (no S6 with-contenv available)
        bash "$script"
    done
fi

# ─── Setup persistent data directory ─────────────────────────────────────────
# /opt/data is a Docker VOLUME in the upstream image; it is NOT persistent
# across addon updates/reinstalls in HA.  Use the addon_config directory
# which is mapped by "addon_config:rw" in config.yaml and survives restarts.
HA_DATA_DIR="/addon_configs/maintainerr"
echo "[Maintainerr] Setting up data directory: $HA_DATA_DIR"
mkdir -p "$HA_DATA_DIR"

# Copy any seed / initial data from the upstream volume on first run
if [ -d /opt/data ] && [ ! -f "$HA_DATA_DIR/.initialized" ]; then
    cp -rn /opt/data/. "$HA_DATA_DIR/" 2>/dev/null || true
fi

# Only chown on first run to avoid slow startup on large directories
if [ ! -f "$HA_DATA_DIR/.initialized" ]; then
    chown -R node:node "$HA_DATA_DIR"
    touch "$HA_DATA_DIR/.initialized"
fi

# Tell Maintainerr to use the persistent directory
export DATA_DIR="$HA_DATA_DIR"

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
exec gosu node /opt/app/start.sh
