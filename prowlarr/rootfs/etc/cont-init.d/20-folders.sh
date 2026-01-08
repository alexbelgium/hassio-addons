#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=prowlarr

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    tar -C /homeassistant/addons_config/"$slug" --exclude=addons_config -cf - . | tar -C /config -xf - || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi
