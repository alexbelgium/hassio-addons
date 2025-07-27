#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -d /homeassistant/addons_config/calibre-web ] && [ ! -L /homeassistant/addons_config/calibre-web ]; then
    if [ "$(ls -A /homeassistant/addons_config/calibre-web)" ]; then
        echo "Moving database to new location /config"
        cp -rf /homeassistant/addons_config/calibre-web/* "$LOCATION"/
    fi
    rm -r /homeassistant/addons_config/calibre-web
fi
