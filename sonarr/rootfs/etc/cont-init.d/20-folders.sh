#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

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

slug=sonarr

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug to /addon_configs/xxx-$slug"
    cp -rnf /homeassistant/addons_config/"$slug"/. /config/ || true
    mv /homeassistant/addons_config/"$slug" /homeassistant/addons_config/"$slug"_migrated
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi

# Sonarr v4 looks for ffprobe in its own binary directory (/app/sonarr/bin/)
# via GlobalFFOptions.Configure(options => options.BinaryFolder = AppDomain.CurrentDomain.BaseDirectory)
# Symlink the system-installed ffprobe there so Sonarr can find a working copy
if [ -f /usr/bin/ffprobe ] && [ -d /app/sonarr/bin ]; then
    ln -sf /usr/bin/ffprobe /app/sonarr/bin/ffprobe
    echo "Symlinked /usr/bin/ffprobe to /app/sonarr/bin/ffprobe"
fi
