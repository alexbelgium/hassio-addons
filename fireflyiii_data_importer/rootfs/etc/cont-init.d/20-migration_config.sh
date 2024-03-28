#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

slug=fireflyiii_data_importer
CONFIGSOURCE="$(bashio::config "CONFIG_LOCATION")"

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug"
    mv /homeassistant/addons_config/"$slug"/* "$CONFIGSOURCE"/ || true
    rm -r /homeassistant/addons_config/"$slug"
fi

# Create directory
mkdir -p "$CONFIGSOURCE"/import_files
mkdir -p "$CONFIGSOURCE"/configurations

# Make sure permissions are right
chown -R "root:root" "$CONFIGSOURCE"
chmod -R 755 "$CONFIGSOURCE"
