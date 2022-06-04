#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#create folders
datadirectory=$(bashio::config 'data_directory')
mkdir -p \
    "$datadirectory" \
    /data/config/nextcloud/config \
    /data/config/nextcloud/data \
    /data/config/www/nextcloud/config

#permissions
PUID="$(bashio::config 'PUID')"
GUID="$(bashio::config 'GUID')"
chown -R "$PUID":"$GUID" \
    "$datadirectory" \
    /data/config/nextcloud/config \
    /data/config/nextcloud/data \
    /data/config/www/nextcloud/config

chown -R abc:abc \
    /var/lib/nginx

rm -r /data/config/www/nextcloud/assets &>/dev/null || true
chmod -R 777 /data/config 
