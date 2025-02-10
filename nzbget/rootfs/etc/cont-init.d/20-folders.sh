#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=nzbget

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    cp -rnf /homeassistant/addons_config/"$slug"/* /config/
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

chmod 777 /config/*
