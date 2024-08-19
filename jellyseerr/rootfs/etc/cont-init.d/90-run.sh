#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Create files
CONFIG_LOCATION="/config/addons_config/jellyseerr"
bashio::log.info "Config stored in $CONFIG_LOCATION"
mkdir -p "$CONFIG_LOCATION"
cp -rnT /app/config "$CONFIG_LOCATION"/
rm -r /app/config
ln -s "$CONFIG_LOCATION" /app/config
chmod -R 755 "$CONFIG_LOCATION"

# Create files
JELLYFIN_TYPE=$(bashio::config 'TYPE')
export JELLYFIN_TYPE
TZ=$(bashio::config 'TZ')
export TZ

yarn start
