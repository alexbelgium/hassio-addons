#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /share/storage/movies ]; then
    echo "Creating /share/storage/movies"
    mkdir -p /share/storage/movies
    chown -R "$PUID:$PGID" /share/storage/movies
fi

if [ ! -d /share/storage/tv ]; then
    echo "Creating /share/storage/tv"
    mkdir -p /share/storage/tv
    chown -R "$PUID:$PGID" /share/storage/tv
fi

if [ ! -d /share/downloads ]; then
    echo "Creating /share/downloads"
    mkdir -p /share/downloads
    chown -R "$PUID:$PGID" /share/downloads
fi

slug=bazarr

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    tar -C /homeassistant/addons_config/"$slug" --exclude=addons_config -cf - . | tar -C /config -xf - || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi
