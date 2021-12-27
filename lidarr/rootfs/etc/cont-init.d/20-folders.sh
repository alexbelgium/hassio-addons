#!/usr/bin/with-contenv bash

if [ ! -d /share/music ]; then
  echo "Creating /share/music"
  mkdir -p /share/music
  chown -R abc:abc /share/music
fi

if [ ! -d /share/downloads ]; then
  echo "Creating /share/downloads"
  mkdir -p /share/downloads
  chown -R abc:abc /share/downloads
fi

if [ -d /config/lidarr ]; then
  echo "Moving to new location /config/addons_config/lidarr"
  mkdir -p /config/addons_config/lidarr
  chown -R abc:abc /config/addons_config/lidarr
  mv /config/lidarr/* /config/addons_config/lidarr/
fi

if [ ! -d /config/addons_config/lidarr ]; then
  echo "Creating /config/addons_config/lidarr"
  mkdir -p /config/addons_config/lidarr
  chown -R abc:abc /config/addons_config/lidarr
fi