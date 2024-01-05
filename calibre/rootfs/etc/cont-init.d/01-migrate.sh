#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -d /homeassistant/addons_config/calibre ]; then
    echo "Moving database to new location /config"
    cp -rnf /homeassistant/addons_config/calibre/* /config/
    rm -r /homeassistant/addons_config/calibre
fi
