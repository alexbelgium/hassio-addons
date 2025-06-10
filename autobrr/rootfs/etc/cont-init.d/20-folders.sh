#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /data/autobrr ]; then
  echo "Creating /data/autobrr"
  mkdir -p /data/autobrr
  chown -R "$(bashio::config "PUID"):$(bashio::config "PGID")" /data/autobrr
fi

if [ ! -d /config/addons_config/autobrr ]; then
  echo "Creating /config/addons_config/autobrr"
  mkdir -p /config/addons_config/autobrr
  chown -R "$(bashio::config "PUID"):$(bashio::config "PGID")" /config/addons_config/autobrr
fi
