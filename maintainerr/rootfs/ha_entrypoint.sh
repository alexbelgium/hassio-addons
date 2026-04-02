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
mkdir -p "$DATA_DIR" "$DATA_DIR/logs"

# Preserve any seed data from the Docker volume before replacing it.
# /opt/data is a Docker VOLUME mount and cannot be removed, so instead of
# replacing the directory with a symlink, we symlink each item inside it.
if [ -d /opt/data ] && [ ! -L /opt/data ]; then
    cp -rn /opt/data/. "$DATA_DIR/" 2>/dev/null || true
    # Remove contents inside /opt/data (the directory itself stays)
    rm -rf /opt/data/*
fi

# Create symlinks for each item in $DATA_DIR inside /opt/data
for item in "$DATA_DIR"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    ln -sfn "$item" "/opt/data/$name"
done

# Only chown on first run to avoid slow startup on large directories
if [ ! -f "$DATA_DIR/.initialized" ]; then
    chown -R node:node "$DATA_DIR"
    touch "$DATA_DIR/.initialized"
fi
export DATA_DIR

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
gosu node /opt/app/start.sh &

# ─── Wait for Maintainerr to become available, then start Nginx ──────────────
echo "[Maintainerr] Waiting for application to be ready..."
for _ in $(seq 1 900); do
    if curl -s -o /dev/null -f "http://127.0.0.1:${UI_PORT:-6246}" 2>/dev/null; then
        break
    fi
    sleep 1
done
echo "[Maintainerr] Starting Nginx..."
exec nginx -c /etc/nginx/nginx.conf
