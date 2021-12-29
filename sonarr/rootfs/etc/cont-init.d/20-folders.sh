#!/bin/bash

if [ ! -d /share/storage/movies ]; then
  echo "Creating /share/storage/movies"
  mkdir -p /share/storage/movies
  chown -R abc:abc /share/storage/movies
fi

if [ ! -d /share/downloads ]; then
  echo "Creating /share/downloads"
  mkdir -p /share/downloads
  chown -R abc:abc /share/downloads
fi

if [ -d /config/sonarr ]; then
  echo "Moving to new location /config/addons_config/sonarr"
  mkdir -p /config/addons_config/sonarr
  chown -R abc:abc /config/addons_config/sonarr
  mv /config/sonarr/* /config/addons_config/sonarr/
  rm -r /config/sonarr
fi

if [ ! -d /config/addons_config/sonarr ]; then
  echo "Creating /config/addons_config/sonarr"
  mkdir -p /config/addons_config/sonarr
  chown -R abc:abc /config/addons_config/sonarr
fi
