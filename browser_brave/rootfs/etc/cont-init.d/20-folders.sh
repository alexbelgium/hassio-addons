#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")


# Create cache
mkdir -p /.cache
chmod 755 /.cache
if [ -d "/config/.cache" ]; then
    cp -rf /config/.cache /.cache
    rm -r /config/.cache
fi
ln -sf /config/.cache /.cache

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" /config
chmod -R 700 /config
