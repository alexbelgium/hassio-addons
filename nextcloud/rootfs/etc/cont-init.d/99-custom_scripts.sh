#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

for file in /config/addons_config/nextcloud/*.sh
do
    if [ -e "$file" ]; then
        bashio::log.info "Executing $file"
        bash "$file"
    fi
done

# Use php7
if [ -f /data/config/crontabs/root ]; then
    sed -i "s|php7|php|g" /data/config/crontabs/root
fi
