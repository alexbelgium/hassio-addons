#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=jellyfin

# Migration to new /config logic
if [[ "$LOCATION" == "/config/addons_config/"* ]]; then
    bashio::log.warning "Data folder was $LOCATION, it is migrated to /config/data. The previous folder is renamed to _migrated"    
    LOCATION="${LOCATION/config/homeassistant}"
    mkdir -p /config/data
    if [ -d $LOCATION ]; then
        cp -rf "$LOCATION"/* /config/data/
        mv "$LOCATION" "$LOCATION"_migrated
    fi
    bashio::addon.option "data_location" "/config/data"
fi

# Migrate autoscripts
if [ -f "/homeassistant/addons_autoscripts/$slug.sh" ]; then
    bashio::log.warning "Migrating autoscript"
    mv /homeassistant/addons_autoscripts/$slug.sh /config/ || true
fi

# Migrate config.yaml
if [ -f "/homeassistant/addons_config/$slug/config.yaml" ]; then
    bashio::log.warning "Migrating config.yaml"
    mv /homeassistant/addons_config/$slug/config.yaml /config/ || true
fi
