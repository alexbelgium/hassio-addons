#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

CONFIGLOCATION=$(bashio::config "CONFIG_LOCATION")


if [ ! -d "$CONFIGLOCATION" ]; then
CONFIGLOCATION="$(dirname "$CONFIGLOCATION")"
fi

sed -i "s| /data/config| $CONFIGLOCATION|g" /etc/cont-init.d/*
sed -i "s| /data/config| $CONFIGLOCATION|g" /defaults/* || true

# Create directory
mkdir -p "$CONFIGLOCATION"/config

# Copy previous config if existing
if [ -d /data/config ]; then
    echo "Moving to new location $CONFIGLOCATION"
    mv /data/config/* "$CONFIGLOCATION"/config/
    rm -r /data/config
fi

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGLOCATION"

# Exporting config location
bashio::log.info "Config file can be found in $CONFIGLOCATION"
sed -i "1a export PAPERMERGE_CONFIG_FILE=$CONFIGLOCATION" /etc/services.d/papermerge/run
