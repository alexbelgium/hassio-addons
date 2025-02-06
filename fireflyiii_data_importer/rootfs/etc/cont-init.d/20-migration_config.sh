#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

slug=fireflyiii_data_importer

if [[ "$(bashio::config "CONFIG_LOCATION")" == *"/addons_config/fireflyiii_data_importer"* ]]; then
    bashio::log.warning "Reset CONFIG_LOCATION to /config"
    bashio::addon.option "CONFIG_LOCATION" "/config"
    bashio::addon.restart
fi

CONFIGSOURCE="$(bashio::config "CONFIG_LOCATION")"

if [ -d "/homeassistant/addons_config/$slug" ] && [ ! -f "/homeassistant/addons_config/$slug/migrated" ]; then
    echo "Migrating /homeassistant/addons_config/$slug"
    sudo mv /homeassistant/addons_config/"$slug"/* "$CONFIGSOURCE"/
    sudo touch /homeassistant/addons_config/$slug/migrated
fi

# Create directory
sudo mkdir -p "$CONFIGSOURCE"/import_files
sudo mkdir -p "$CONFIGSOURCE"/configurations

# Make sure permissions are right
sudo chown -R "www-data:www-data" "$CONFIGSOURCE"
sudo chmod -R 755 "$CONFIGSOURCE"
