#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Degoog keeps its settings, plugins, themes, engines and sqlite indexer in its
# data directory. services.d/degoog/run points DEGOOG_DATA_DIR at /config, the
# addon_config mount, which matches the upstream compose file's
# "./data:/app/data" volume : an existing data folder can be copied in as is.
bashio::log.info "Data stored in /config"

# Recursive, like the upstream entrypoint does for /app/data : plugins and
# themes are installed by the app itself, so a PUID change must hand them over
# too. Numbered 20- so it sorts after 00-global_var.sh, which exports PUID/PGID.
chown -R "${PUID:-0}:${PGID:-0}" /config
