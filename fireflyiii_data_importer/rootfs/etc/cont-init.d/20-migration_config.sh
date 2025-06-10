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
	mv /homeassistant/addons_config/"$slug"/* "$CONFIGSOURCE"/
	touch /homeassistant/addons_config/$slug/migrated
fi

# Create directory
mkdir -p "$CONFIGSOURCE"/import_files
mkdir -p "$CONFIGSOURCE"/configurations

# Make sure permissions are right
chown -R "www-data:www-data" "$CONFIGSOURCE"
chmod -R 755 "$CONFIGSOURCE"
