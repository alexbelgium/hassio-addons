#!/bin/bash
# shellcheck shell=bash
set -e

###############################################################################
# Home Assistant Addon entrypoint for Maintainerr
# Runs cont-init.d scripts then drops privileges and starts the app.
###############################################################################

# ─── Source bashio library so init scripts can use bashio:: functions ─────────
_bashio_loaded=false
for _f in /usr/lib/bashio/bashio /usr/lib/bashio/bashio.sh; do
    if [ -f "$_f" ]; then
        # shellcheck disable=SC1090
        source "$_f"
        _bashio_loaded=true
        break
    fi
done
if [ "$_bashio_loaded" = false ]; then
    echo "[Maintainerr] WARNING: bashio library not found; init scripts using bashio functions will fail"
fi

# ─── Run cont-init.d scripts ─────────────────────────────────────────────────
if [ -d /etc/cont-init.d ]; then
    for script in /etc/cont-init.d/*.sh; do
        [ -f "$script" ] || continue
        echo "[Maintainerr] Running init script: $script"
        # Run in subshell to isolate side effects; bashio functions are inherited
        # shellcheck disable=SC1090
        ( source "$script" )
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

# ─── Inject ingress base path into the built UI files ─────────────────────────
# The upstream Maintainerr Vite build embeds /__PATH_PREFIX__ as a placeholder
# for the base URL. The upstream start.sh replaces it with $BASE_PATH at runtime.
# For HA ingress, the base path is the dynamic ingress entry (e.g.
# /api/hassio_ingress/<token>). We perform the replacement here so the React
# Router basename and all asset/API URLs point through the ingress path.
# We intentionally do NOT export BASE_PATH so that the NestJS server keeps its
# routes at the root — nginx's rewrite rule strips the ingress prefix on the
# server side.
ingress_entry="$(bashio::addon.ingress_entry 2>/dev/null || true)"
if [ -n "$ingress_entry" ]; then
    UI_DIST_DIR="/opt/app/apps/server/dist/ui"
    if [ -d "$UI_DIST_DIR" ]; then
        echo "[Maintainerr] Setting ingress base path: $ingress_entry"
        find "$UI_DIST_DIR" -type f -not -path '*/node_modules/*' \
            -print0 | xargs -0 sed -i "s,/__PATH_PREFIX__,${ingress_entry},g" 2>/dev/null || true
    fi
fi

# ─── Start Maintainerr as unprivileged node user ─────────────────────────────
echo "[Maintainerr] Starting application on port ${UI_PORT:-6246}..."
exec gosu node /opt/app/start.sh &
exec nginx
