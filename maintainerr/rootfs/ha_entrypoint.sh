#!/bin/bash
# shellcheck shell=bash
set -e

###############################################################################
# Home Assistant Addon entrypoint for Maintainerr
# Runs cont-init.d scripts then drops privileges and starts the app.
###############################################################################

# ─── Run cont-init.d scripts ─────────────────────────────────────────────────
if [ -d /etc/cont-init.d ]; then
    for script in /etc/cont-init.d/*.sh; do
        [ -f "$script" ] || continue
        sed -i '1s|.*|#!/usr/bin/env bashio|' "$script"
        echo "[Maintainerr] Running init script: $script"
        bashio "$script"
    done
fi

# ─── Setup persistent data directory ─────────────────────────────────────────
# The upstream app hardcodes /opt/data for its database and logs.
# The Dockerfile rewrites all /opt/data references to /config/data at build time.
# At runtime we copy any seed data from /opt/data to /config/data (persistent
# via addon_config:rw) without overwriting existing files.
DATA_DIR="/config/data"
echo "[Maintainerr] Setting up data directory: $DATA_DIR"
mkdir -p "$DATA_DIR" "$DATA_DIR/logs"

# Copy any seed/existing data from /opt/data to /config/data (don't overwrite)
if [ -d /opt/data ] && [ "$(ls -A /opt/data 2>/dev/null)" ]; then
    echo "[Maintainerr] Copying existing files from /opt/data to $DATA_DIR..."
    cp -rn /opt/data/. "$DATA_DIR/" 2>/dev/null || true
fi

# Apply permissions/ownership once so copied files are also covered
chmod -R 777 "$DATA_DIR"
if [ ! -f "$DATA_DIR/.initialized" ]; then
    chown -R node:node "$DATA_DIR"
    touch "$DATA_DIR/.initialized"
fi
export DATA_DIR

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
exec gosu node /opt/app/start.sh
# exec nginx
