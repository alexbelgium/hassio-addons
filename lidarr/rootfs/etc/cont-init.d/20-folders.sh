#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -d /share/music ]; then
  echo "Creating /share/music"
  mkdir -p /share/music
  chown -R "$PUID:$PGID" /share/music
fi

if [ ! -d /share/downloads ]; then
  echo "Creating /share/downloads"
  mkdir -p /share/downloads
  chown -R "$PUID:$PGID" /share/downloads
fi

if [ -d /config/lidarr ] && [ ! -d /config/addons_config/lidarr ]; then
  echo "Moving to new location /config/addons_config/lidarr"
  mkdir -p /config/addons_config/lidarr
  chmod 777 /config/addons_config/lidarr
  mv /config/lidarr/* /config/addons_config/lidarr/
  rm -r /config/lidarr
fi

if [ ! -d /config/addons_config/lidarr ]; then
  echo "Creating /config/addons_config/lidarr"
  mkdir -p /config/addons_config/lidarr
  chmod 777 /config/addons_config/lidarr
fi
