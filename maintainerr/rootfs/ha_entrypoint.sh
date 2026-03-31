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
# The upstream app hardcodes /opt/data for its database and logs
# (typeOrmConfig.ts → /opt/data/maintainerr.sqlite, logs → /opt/data/logs/).
# /opt/data is declared as a Docker VOLUME in the upstream image, which is NOT
# persistent across addon updates/reinstalls in HA.
# Redirect /opt/data → /config (persistent via addon_config:rw) with a symlink.
DATA_DIR="/config"
echo "[Maintainerr] Setting up data directory: $DATA_DIR"
mkdir -p "$DATA_DIR"

# Preserve any seed data from the Docker volume before replacing it
if [ -d /opt/data ] && [ ! -L /opt/data ]; then
    cp -rn /opt/data/. "$DATA_DIR/" 2>/dev/null || true
    rm -rf /opt/data
fi
ln -sfn "$DATA_DIR" /opt/data

# Only chown on first run to avoid slow startup on large directories
if [ ! -f "$DATA_DIR/.initialized" ]; then
    chown -R node:node "$DATA_DIR"
    touch "$DATA_DIR/.initialized"
fi
export DATA_DIR

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
exec gosu node /opt/app/start.sh
