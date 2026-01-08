#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /share/storage/ebook ]; then
    echo "Creating /share/storage/ebook"
    mkdir -p /share/storage/ebook
    chown -R "$PUID:$PGID" /share/storage/ebook
fi

if [ ! -d /share/downloads ]; then
    echo "Creating /share/downloads"
    mkdir -p /share/downloads
    chown -R "$PUID:$PGID" /share/downloads
fi

slug=readarr

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    cp -rnf /homeassistant/addons_config/"$slug"/* /config/ || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/readarr ]; then
    mv /config/readarr/{.,}* /config/ || true
    rmdir /config/readarr || true
fi
