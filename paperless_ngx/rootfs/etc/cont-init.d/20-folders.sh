#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug=paperless_ng

if [ ! -d /config/addons_config/$slug ]; then
    echo "Creating /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
fi

chmod 777 /config/addons_config/$slug
