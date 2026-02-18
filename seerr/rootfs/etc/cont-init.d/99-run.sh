#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

rm -r /app/config
ln -sf /config /app/config

chown -R "$PUID:$PGID" /config || true

cd /app || true

npm start
