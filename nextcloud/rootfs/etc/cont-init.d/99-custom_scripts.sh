#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

for file in /config/addons_config/nextcloud/*.sh
do
    if [ -e "$file" ]; then
        bashio::log.info "Executing $file"
        bash "$file"
    fi
done
