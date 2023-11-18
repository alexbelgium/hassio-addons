#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug="${HOSTNAME#*-}"
bashio::log.green "Execute /config/addons_autoscripts/${slug}.sh if existing"
bashio::log.green "---------------------------------------------------------"
echo "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

# Check type of config folder
if [ ! -f /config/configuration.* ]; then
    # Migrate previous script
    if [ -f /config/addons_autoscripts/"${slug}".sh ]; then
        mv -f /config/addons_autoscripts/"${slug}".sh /config/"${slug}".sh
    fi
    # New config location
    CONFIGLOCATION="/config"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_autoscripts"
    mkdir -p /config/addons_autoscripts
fi

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

