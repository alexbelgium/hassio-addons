#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=jellyfin
LOCATION="$(bashio::config 'data_location')"

if [[ "$LOCATION" == "/share/jellyfin" ]] && [ ! -d /share/jellyfin ] && [ -d /homeassistant/addons_config/jellyfin ]; then
    mkdir -p /share/jellyfin
    if [ -d /homeassistant/addons_config/jellyfin ]; then
        bashio::log.warning "Data folder was /config/addons_config/jellyfin, it is migrated to /share/data. The previous folder is renamed to _migrated"    
        cp -rn /homeassistant/addons_config/jellyfin/* /share/jellyfin/ || true
        mv /homeassistant/addons_config/jellyfin /homeassistant/addons_config/jellyfin_migrated
    fi
fi

if [ -d /homeassistant/addons_config/jellyfin_migrated ]; then
  mkdir -p /config/addons_config
  ln -sf "$LOCATION" /config/addons_config/jellyfin
  chown -R "$PUID:$PGID" "$LOCATION"
fi

# Migration to new /config logic
if [[ "$LOCATION" == "/config/addons_config/"* ]]; then
    bashio::log.warning "Data folder was $LOCATION, it is migrated to /config/data. The previous folder is renamed to _migrated"    
    LOCATION="${LOCATION/config/homeassistant}"
    mkdir -p /config/data
    if [ -d "$LOCATION" ]; then
        cp -rn "$LOCATION"/* /config/data/
        mv "$LOCATION" "$LOCATION"_migrated
    fi
    bashio::addon.option "data_location" "/config/data"
fi

if [[ -d "/homeassistant/addons_config/jellyfin" ]]; then
    bashio::log.warning "Data folder was found in /config/addons_config/jellyfin, it is migrated to /config/data. The previous folder is renamed to _migrated"
    mkdir -p /config/data
    cp -rn "/homeassistant/addons_config/jellyfin/*" /config/data/
    mv /homeassistant/addons_config/jellyfin /homeassistant/addons_config/jellyfin_migrated
    ln -sf /config/data /config/addons_config/jellyfin
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
