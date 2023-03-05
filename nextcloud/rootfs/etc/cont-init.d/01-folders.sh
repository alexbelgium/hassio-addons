#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")
datadirectory=$(bashio::config 'data_directory')

bashio::log.info "Checking permissions"
mkdir -p /data/config
mkdir -p "$datadirectory"
chmod 755 -R "$datadirectory"
chmod 755 -R /data/config
chown -R "$PUID:$PGID" "$datadirectory"
chown -R "$PUID:$PGID" "/data/config"

# Clean nginx files at each reboot
if [ -d /data/config/nginx ]; then
  rm -r /data/config/nginx
fi
