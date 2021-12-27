#!/usr/bin/with-contenv bash

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

if [ ! -d /config/bazarr ]; then
  echo "Creating /config/bazarr"
  mkdir -p /config/bazarr
  chown -R abc:abc /config/bazarr
fi
