#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

PUID="$(bashio::config 'PUID' || echo 1000)"
PGID="$(bashio::config 'PGID' || echo 1000)"

echo "Creating /data/organizr"
mkdir -p /data/organizr
chown "$PUID:$PGID" /data/organizr
