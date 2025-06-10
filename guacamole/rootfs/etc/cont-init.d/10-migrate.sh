#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

slug=guacamole

if [ -d /homeassistant/addons_config/"$slug" ] && [ ! -d /config/postgres ]; then
  echo "Moving database to new location /config"
  cp -rf /homeassistant/addons_config/"$slug"/* /config/
fi
