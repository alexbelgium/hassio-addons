#!/bin/bash

if [ ! -d /jellyfin ]; then
  echo "Creating /jellyfin"
  mkdir -p /jellyfin
  chown -R abc:abc /jellyfin
fi

if [ ! -d /share/storage/tv ]; then
  echo "Creating /share/storage/tv"
  mkdir -p /share/storage/tv
  chown -R abc:abc /share/storage/tv
fi

if [ ! -d /share/storage/movies ]; then
  echo "Creating /share/storage/movies"
  mkdir -p /share/storage/movies
  chown -R abc:abc /share/storage/movies
fi

if [ ! -d /share/jellyfin ]; then
  echo "Creating /share/jellyfin"
  mkdir -p /share/jellyfin
  chown -R abc:abc /share/jellyfin
fi

# links

if [ ! -d /jellyfin/cache ]; then
  echo "Creating link for /jellyfin/cache"
  mkdir -p /share/jellyfin/cache
  chown -R abc:abc /share/jellyfin/cache
  ln -s /share/jellyfin/cache /jellyfin/cache
fi


if [ -d /config/jellyfin ] && [ ! -d /config/addons_config/bazarr ]; then
  echo "Moving to new location /config/addons_config/jellyfin"
  mkdir -p /config/addons_config/jellyfin
  chown -R abc:abc /config/addons_config/jellyfin
  mv /config/jellyfin/* /config/addons_config/jellyfin/
  rm /config/jellyfin
fi

if [ ! -d /config/addons_config/jellyfin ]; then
  echo "Creating /config/addons_config/jellyfin"
  mkdir -p /config/addons_config/jellyfin
  chown -R abc:abc /config/addons_config/jellyfin
fi

if [ ! -d /jellyfin/data ]; then
  echo "Creating link for /jellyfin/data"
  mkdir -p /share/jellyfin/data
  chown -R abc:abc /share/jellyfin/data
  ln -s /share/jellyfin/data /jellyfin/data
fi

if [ ! -d /jellyfin/logs ]; then
  echo "Creating link for /jellyfin/logs"
  mkdir -p /share/jellyfin/logs
  chown -R abc:abc /share/jellyfin/logs
  ln -s /share/jellyfin/logs /jellyfin/logs
fi

if [ ! -d /jellyfin/metadata ]; then
  echo "Creating link for /jellyfin/metadata"
  mkdir -p /share/jellyfin/metadata
  chown -R abc:abc /share/jellyfin/metadata
  ln -s /share/jellyfin/metadata /jellyfin/metadata
fi

if [ ! -d /jellyfin/plugins ]; then
  echo "Creating link for /jellyfin/plugins"
  mkdir -p /share/jellyfin/plugins
  chown -R abc:abc /share/jellyfin/plugins
  ln -s /share/jellyfin/plugins /jellyfin/plugins
fi

if [ ! -d /jellyfin/root ]; then
  echo "Creating link for /jellyfin/root"
  mkdir -p /share/jellyfin/root
  chown -R abc:abc /share/jellyfin/root
  ln -s /share/jellyfin/root /jellyfin/root
fi
