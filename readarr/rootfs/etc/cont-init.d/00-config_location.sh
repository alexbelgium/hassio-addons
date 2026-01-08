#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.has_value 'CONFIG_LOCATION'; then
    CONFIG_LOCATION="$(bashio::config 'CONFIG_LOCATION')"
    # Modify if it is a base directory
    if [[ "$CONFIG_LOCATION" == *.* ]]; then CONFIG_LOCATION="$(dirname "$CONFIG_LOCATION")"; fi
else
    CONFIG_LOCATION="/config"
fi
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R "$PUID:$PGID" "$CONFIG_LOCATION"

if [ "$CONFIG_LOCATION" != "/config" ]; then
    # shellcheck disable=SC2013
    for file in $(grep -sril "/config" /etc /defaults); do
        sed -i "s|/config|$CONFIG_LOCATION|g" "$file"
    done
fi
