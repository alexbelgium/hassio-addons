#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug=paperless_ng

if [ -d "/homeassistant/addons_config/$slug" ]; then
  echo "Migrating /homeassistant/addons_config/$slug"
  mv /homeassistant/addons_config/"$slug"/media /config/ || true
  mv /homeassistant/addons_config/"$slug"/consume /config/ || true
  mkdir -p /config/data
  mv /homeassistant/addons_config/"$slug"/* /config/data/ || true
  rm -r /homeassistant/addons_config/"$slug"
fi
