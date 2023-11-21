#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define slug if needed
slug="${HOSTNAME#*-}"

# Check type of config folder
if [ ! -f /config/configuration.yaml ] && [ ! -f /config/configuration.json ]; then
    # Migrate previous script
    if [ -f /homeassistant/addons_autoscripts/"${slug}".sh ]; then
        echo "Migrating scripts to new config location"
        mv -f /homeassistant/addons_autoscripts/"${slug}".sh /config/"${slug}".sh
    fi
    # New config location
    CONFIGLOCATION="/config"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_autoscripts"
    mkdir -p /config/addons_autoscripts
fi

bashio::log.green "Execute $CONFIGLOCATION/${slug}.sh if existing"
bashio::log.green "---------------------------------------------------------"
echo "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

# Execute scripts
if [ -f "$CONFIGLOCATION/${slug}".sh ]; then
    bashio::log.green "... script found, executing"
    # Convert scripts to linux
    dos2unix "$CONFIGLOCATION/${slug}".sh || true
    chmod +x "$CONFIGLOCATION/${slug}".sh || true
    /."$CONFIGLOCATION/${slug}".sh
else
    bashio::log.green "... no script found, exiting"
fi
