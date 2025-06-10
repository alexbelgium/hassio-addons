#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.has_value 'CONFIG_LOCATION'; then
  CONFIG_LOCATION="$(bashio::config 'CONFIG_LOCATION')"
  # Modify if it is a base directory
  if [[ "$CONFIG_LOCATION" == *.* ]]; then CONFIG_LOCATION="$(dirname "$CONFIG_LOCATION")"; fi
fi

CONFIG_LOCATION=$(bashio::config 'CONFIG_LOCATION')
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R "$PUID:$PGID" "$CONFIG_LOCATION"

# shellcheck disable=SC2013
for file in $(grep -sril "/config/addons_config/readarr" /etc /defaults); do
  sed -i "s|/config/addons_config/readarr|$CONFIG_LOCATION|g" "$file"
done
