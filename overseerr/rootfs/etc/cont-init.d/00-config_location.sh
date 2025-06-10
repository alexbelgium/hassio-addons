#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

CONFIG_LOCATION=$(bashio::config 'CONFIG_LOCATION')
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R "$PUID:$PGID" "$CONFIG_LOCATION"
chmod -R 755 "$CONFIG_LOCATION"

# shellcheck disable=SC2013
for file in $(grep -Esril "/config/addons_config/overseerr" /etc/logrotate.d /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do
  sed -i "s=/config/addons_config/overseerr=$CONFIG_LOCATION=g" "$file"
done
