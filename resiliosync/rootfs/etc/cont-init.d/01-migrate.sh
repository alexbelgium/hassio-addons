#!/bin/bash

# Migrate files for new config location
slug="resiliosync"
config_location="$(bashio::config 'config_location')"
config_location="${config_location/\/config/\/homeassistant}"

if [ -f "$config_location/config.yaml" ] && [ ! -f "$config_location/migrated" ]; then
	bashio::log.warning "Migrating config.yaml"
	mv "/homeassistant/addons_config/$slug"/* /config/ || true
	echo "Migrated to internal config folder accessible at /addon_configs/xxx-$slug" >"/homeassistant/addons_config/$slug/migrated"
fi

if [ -f "/homeassistant/addons_autoscripts/$slug.sh" ]; then
	bashio::log.warning "Migrating autoscript"
	mv /homeassistant/addons_autoscripts/$slug.sh /config/ || true
fi
