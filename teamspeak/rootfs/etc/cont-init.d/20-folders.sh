#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LOCATION=$(bashio::config 'data_location')

# Data remanence for /teamspeak/save
if [ -d /teamspeak/save ]; then
  cp -rn /teamspeak/save/* "$LOCATION"/
  rm -r /teamspeak/save
fi
mkdir -p "$LOCATION"
ln -sf "$LOCATION" /teamspeak/save

# Data remanence for /data
if [ -d /data ]; then
  cp -rn /data/* "$LOCATION"/
  rm -r /data
fi
mkdir -p "$LOCATION"
rm -r /data
ln -sf "$LOCATION" /data

# Persmissions
chown -R 503:503 "$LOCATION"
chmod 777 "$LOCATION"
