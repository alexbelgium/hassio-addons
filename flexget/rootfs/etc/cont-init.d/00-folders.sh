#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=flexget

if [ -d /config/$slug ]; then
    echo "Moving to new location /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
    chmod 777 /config/addons_config/$slug
    mv /config/$slug/* /config/addons_config/$slug/
    rm -r /config/$slug
fi

if [ ! -d /config/addons_config/$slug ]; then
    echo "Creating /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
    chmod 777 /config/addons_config/$slug
fi
