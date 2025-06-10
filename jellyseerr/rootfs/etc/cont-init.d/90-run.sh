#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Create files
OLD_CONFIG_LOCATION="/config/addons_config/jellyseer"
CONFIG_LOCATION="/config/addons_config/jellyseerr"
bashio::log.info "Config stored in $CONFIG_LOCATION"
mkdir -p "$CONFIG_LOCATION"
cp -rnT /app/config "$CONFIG_LOCATION"/
rm -r /app/config
ln -s "$CONFIG_LOCATION" /app/config
chmod -R 755 "$CONFIG_LOCATION"

#Move files that may be in misspelled directory
if [ -d "$OLD_CONFIG_LOCATION" ]; then
    # Directory Exists
    if [ -z "$(ls -A "$OLD_CONFIG_LOCATION")" ]; then
        # Empty
        rmdir "$OLD_CONFIG_LOCATION"
  else
        # Not Empty
        bashio::log.info "Moving old configuration settings from $OLD_CONFIG_LOCATION to $CONFIG_LOCATION"
        cp -rnT "$OLD_CONFIG_LOCATION" "$CONFIG_LOCATION/"
        rm -r "$OLD_CONFIG_LOCATION"
  fi
fi

# Create files
JELLYFIN_TYPE=$(bashio::config 'TYPE')
export JELLYFIN_TYPE
TZ=$(bashio::config 'TZ')
export TZ

yarn start
