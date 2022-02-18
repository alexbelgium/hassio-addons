#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

CONFIG_LOCATION=$(bashio::config 'CONFIG_LOCATION')
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R abc:abc "$CONFIG_LOCATION"

sed -i "s|/config/readarr|$CONFIG_LOCATION|g" /etc/services.d/readarr/run
sed -i "s|/config/readarr|$CONFIG_LOCATION|g" /etc/cont-init.d/30-config
