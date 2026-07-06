#!/usr/bin/env bashio
# shellcheck shell=bash

bashio::log.info "Starting Spotify to Plex"

# Persist the app's /app/config into the HA add-on config dir (/config)
CONFIG_TARGET="/config"
mkdir -p "$CONFIG_TARGET"

if [ -d /app/config ] && [ ! -L /app/config ]; then
    if cp -rn /app/config/. "$CONFIG_TARGET/"; then
        rm -rf /app/config
    else
        bashio::log.error "Failed to migrate /app/config to $CONFIG_TARGET; leaving original config in place"
    fi
fi

if [ ! -e /app/config ] || [ -L /app/config ]; then
    ln -sfn "$CONFIG_TARGET" /app/config
fi

# Auto-generate a persistent ENCRYPTION_KEY when the user leaves it blank.
# Upstream reads this via Buffer.from(ENCRYPTION_KEY, 'hex') for aes-256-cbc,
# so it must be exactly 64 hex characters (not base64).
if [ -z "${ENCRYPTION_KEY:-}" ]; then
    KEY_FILE="$CONFIG_TARGET/.encryption_key"
    if [ -f "$KEY_FILE" ]; then
        ENCRYPTION_KEY="$(cat "$KEY_FILE")"
    else
        ENCRYPTION_KEY="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
        printf '%s' "$ENCRYPTION_KEY" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        bashio::log.info "Generated a new ENCRYPTION_KEY (stored in the add-on config dir)"
    fi
    export ENCRYPTION_KEY
fi

# Hand off to the upstream supervisord (web + scraper + scheduler)
cd /app || true
exec /docker-entrypoint.sh supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
