#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Setup config directory
if [ -d /app/config ]; then
    rm -r /app/config
fi
ln -sf /config /app/config

# Set permissions
chown -R "$PUID:$PGID" /config || true

bashio::log.info "Seerr initialization complete"
