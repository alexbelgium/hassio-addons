#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LOCATION=$(bashio::config 'data_location')

# Data remanence 
if -d /teamspeak/save; then
  cp -n /teamspeak/save "$LOCATION"
  rm -r /teamspeak/save
fi

mkdir -p "$LOCATION"
ln -sf "$LOCATION" /teamspeak/save
