#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

slug=guacamole

# /config/postgres is also missing for a moment while a PostgreSQL upgrade swaps it
if [ -d /homeassistant/addons_config/"$slug" ] && [ ! -d /config/postgres ] && [ ! -e /config/postgres.upgrade ]; then
    echo "Moving database to new location /config"
    cp -rf /homeassistant/addons_config/"$slug"/* /config/
fi
