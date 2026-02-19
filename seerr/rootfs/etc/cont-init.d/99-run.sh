#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

rm -r /app/config
ln -sf /config /app/config

chown -R "$PUID:$PGID" /config || true

cd /app || true

bashio::log.info "Starting NGinx..."
nginx &

bashio::log.info "Starting app"
exec npm start
