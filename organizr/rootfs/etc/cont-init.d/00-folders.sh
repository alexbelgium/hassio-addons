#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"

echo "Creating /data/organizr"
mkdir -p /data/organizr
chown -R "$PUID:$PGID" /data
