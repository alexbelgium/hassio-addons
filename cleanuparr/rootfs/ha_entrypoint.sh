#!/bin/bash
# shellcheck shell=bash
set -e

###############################################################################
# Home Assistant Addon entrypoint for Cleanuparr
# The .NET app uses /app/config as its data directory.
# We symlink /app/config → /config (the HA app_config mount, HA persistent storage)
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
        sed -i '1s|.*|#!/usr/bin/env bashio|' "$script"
        echo "[Cleanuparr] Running init script: $script"
        bashio "$script"
    done
fi

# ─── Setup persistent data directory ─────────────────────────────────────────
HA_DATA_DIR="/config"
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

# ─── Ingress proxy ───────────────────────────────────────────────────────────
# See /etc/nginx/nginx.conf for why ingress needs a proxy at all.
echo "[Cleanuparr] Starting ingress proxy on port 8099..."
nginx

# ─── Add-on options as environment variables ─────────────────────────────────
# 00-global_var.sh turns /data/options.json, the env_vars list included, into
# /.env. It runs as a child of this script, so sourcing its output here is what
# actually puts those variables in Cleanuparr's environment. Deliberately after
# nginx has started: an env_vars entry cannot then affect the ingress proxy.
#
# Sourcing is only safe because 00-global_var.sh is the sole writer of /.env
# here and quotes every value. 01-config_yaml.sh appends bare KEY=VALUE lines,
# so `MY_VAR: hello world` would run `world` as a command: do not add that
# module to MODULES without quoting its output first.
if [ -f /.env ]; then
    set -a
    # shellcheck disable=SC1091
    . /.env
    set +a
fi

# ─── Start Cleanuparr directly (bypass original /entrypoint.sh) ──────────────
echo "[Cleanuparr] Starting application on port ${HTTP_PORTS:-11011}..."
cd /app
exec ./Cleanuparr
