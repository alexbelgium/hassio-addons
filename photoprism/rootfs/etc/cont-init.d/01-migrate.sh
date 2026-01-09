#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=photoprism

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    cp -rnf /homeassistant/addons_config/"$slug"/. /config/ || true
    echo "Migrated to internal config folder accessible at /addon_configs/xxx-$slug" \
        > "/homeassistant/addons_config/$slug/.migrate"
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi
