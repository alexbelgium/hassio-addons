#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=nzbget

if [ -d "/homeassistant/addons_config/$slug" ] && [ ! -f "/homeassistant/addons_config/$slug/migrated" ]; then
    echo "Migrating /homeassistant/addons_config/$slug"
    mv /homeassistant/addons_config/"$slug"/* /config/
    touch /homeassistant/addons_config/$slug/migrated
fi

chmod 777 /config/*
