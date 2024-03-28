#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

slug=fireflyiii_data_importer

if [ -d "/homeassistant/addons_config/$slug" ]; then
    echo "Migrating /homeassistant/addons_config/$slug"
    mv /homeassistant/addons_config/"$slug"/* /config/ || true
    rm -r /homeassistant/addons_config/"$slug"
fi

# Create directory
mkdir -p /config/import_files
mkdir -p /config/configurations

# Make sure permissions are right
chown -R "root:root" /config
chmod -R 755 /config
