#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R "$PUID:$PGID" "$CONFIG_LOCATION"
