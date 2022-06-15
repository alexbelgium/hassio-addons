#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LOCATION=$(bashio::config 'data_location')

# Data remanence for /teamspeak/save
if [ -d /teamspeak/save ]; then
  cp -rn /teamspeak/save/* "$LOCATION"/ || true
  rm -r /teamspeak/save
fi
ln -sf /data /teamspeak/save
chmod -R 777 /data
