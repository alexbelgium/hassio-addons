#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

CONFIG_LOCATION=$(bashio::config 'CONFIG_LOCATION')
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R abc:abc "$CONFIG_LOCATION"
chmod -R 755 "$CONFIG_LOCATION"

for file in $(grep -Esril "/config/addons_config/overseerr" /etc/logrotate.d /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do
    sed -i "s=/config/addons_config/overseerr=$CONFIG_LOCATION=g" "$file"
done
