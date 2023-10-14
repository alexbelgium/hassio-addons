#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug="${HOSTNAME#*-}"
bashio::log.green "Execute /config/addons_autoscripts/${slug}.sh if existing"
bashio::log.green "---------------------------------------------------------"
echo "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

mkdir -p /config/addons_autoscripts

# Migrate scripts
if [ -f /config/"${slug}".sh ]; then
    mv -f /config/"${slug}".sh /config/addons_autoscripts/"${slug}".sh
fi

# Execute scripts
if [ -f /config/addons_autoscripts/"${slug}".sh ]; then
    bashio::log.green "... script found, executing"
    # Convert scripts to linux
    dos2unix /config/addons_autoscripts/"${slug}".sh || true
    chmod +x /config/addons_autoscripts/"${slug}".sh || true
    /./config/addons_autoscripts/"${slug}".sh
else
    bashio::log.green "... no script found, exiting"
fi

