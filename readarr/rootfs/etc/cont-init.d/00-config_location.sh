#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.has_value 'CONFIG_LOCATION'; then
    CONFIG_LOCATION="$(bashio::config 'CONFIG_LOCATION')"
    # Modify if it is a base directory
    if [[ "$CONFIG_LOCATION" == *.* ]]; then CONFIG_LOCATION="$(dirname $CONFIG_LOCATION)/config.xmlif [[ "$CONFIG_LOCATION" == *.* ]]; then CONFIG_LOCATION="$(dirname $CONFIG_LOCATION)"; fi
; fi
fi

CONFIG_LOCATION=$(bashio::config 'CONFIG_LOCATION')
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R abc:abc "$CONFIG_LOCATION"

sed -i "s|/config/addons_config/readarr|$CONFIG_LOCATION|g" /etc/services.d/readarr/run
sed -i "s|/config/addons_config/readarr|$CONFIG_LOCATION|g" /etc/cont-init.d/30-config
