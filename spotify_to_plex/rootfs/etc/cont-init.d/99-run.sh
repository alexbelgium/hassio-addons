#!/usr/bin/env bashio
# shellcheck shell=bash

bashio::log.info "Starting Spotify to Plex"

# Persist the app's /app/config into the HA add-on config dir (/config)
CONFIG_TARGET="/config"
mkdir -p "$CONFIG_TARGET"
if [ -d /app/config ] && [ ! -L /app/config ]; then
    cp -rn /app/config/. "$CONFIG_TARGET/" 2> /dev/null || true
    rm -rf /app/config
fi
ln -sfn "$CONFIG_TARGET" /app/config

# Auto-generate a persistent ENCRYPTION_KEY when the user leaves it blank
if [ -z "${ENCRYPTION_KEY:-}" ]; then
    if [ -f "$CONFIG_TARGET/.encryption_key" ]; then
        ENCRYPTION_KEY="$(cat "$CONFIG_TARGET/.encryption_key")"
    else
        ENCRYPTION_KEY="$(head -c 32 /dev/urandom | base64)"
        echo "$ENCRYPTION_KEY" > "$CONFIG_TARGET/.encryption_key"
        bashio::log.info "Generated a new ENCRYPTION_KEY (stored in the add-on config dir)"
    fi
    export ENCRYPTION_KEY
fi

# Hand off to the upstream supervisord (web + scraper + scheduler)
cd /app || true
exec /docker-entrypoint.sh supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
