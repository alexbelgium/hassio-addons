#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Create files
CONFIG_LOCATION="/config/addons_config/jellyseer"
bashio::log.info "Config stored in $CONFIG_LOCATION"
mkdir -p "$CONFIG_LOCATION"
if [ -d /data/config ]; then rm -r /data/config; fi
cp -rnT /app/config "$CONFIG_LOCATION"
rm -r /app/config
cp -rn /app/* /data
cp -rn /app/.next /data
rm -r /app
ln -s "$CONFIG_LOCATION" /data/config

# Create files
JELLYFIN_TYPE=$(bashio::config 'TYPE')
export JELLYFIN_TYPE
TZ=$(bashio::config 'TZ')
export TZ

yarn start
