#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

echo "Creating /data/organizr"
mkdir -p /data/organizr
chown -R "$PUID:$PGID" /data
