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
# /opt/data is a Docker VOLUME in the upstream image and cannot be removed.
# Maintainerr supports the DATA_DIR env var to redirect data storage.
DATA_DIR="/config"
echo "[Maintainerr] Setting up data directory: $DATA_DIR"
mkdir -p "$DATA_DIR"
# Only chown on first run to avoid slow startup on large directories
if [ ! -f "$DATA_DIR/.initialized" ]; then
    chown -R node:node "$DATA_DIR"
    touch "$DATA_DIR/.initialized"
fi
export DATA_DIR

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
exec gosu node /opt/app/start.sh
