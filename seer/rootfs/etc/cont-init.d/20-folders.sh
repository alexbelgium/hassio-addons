#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=seer

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /config"
    cp -rnf /homeassistant/addons_config/"$slug"/. /config/ || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/addons_config/seer ]; then
    echo "Migrating /config/addons_config/seer to /config"
    cp -rnf /config/addons_config/seer/. /config/ || true
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi

chown -R "$PUID:$PGID" /config || true
