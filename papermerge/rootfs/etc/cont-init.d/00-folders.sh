#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

CONFIGLOCATION=$(bashio::config "CONFIG_LOCATION")


if [ ! -d "$CONFIGLOCATION" ]; then
    CONFIGLOCATION="$(dirname "$CONFIGLOCATION")"
fi

sed -i "s|/data/config|$CONFIGLOCATION|g" /etc/cont-init.d/*
sed -i "s|/data/config|$CONFIGLOCATION|g" /defaults/*

# Create directory
mkdir -p "$CONFIGLOCATION"/config
