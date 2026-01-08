#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /share/music ]; then
    echo "Creating /share/music"
    mkdir -p /share/music
    chown -R "$PUID:$PGID" /share/music
fi

if [ ! -d /share/downloads ]; then
    echo "Creating /share/downloads"
    mkdir -p /share/downloads
    chown -R "$PUID:$PGID" /share/downloads
fi

slug=lidarr

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    tar -C /homeassistant/addons_config/"$slug" --exclude=addons_config -cf - . | tar -C /config -xf - || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi
