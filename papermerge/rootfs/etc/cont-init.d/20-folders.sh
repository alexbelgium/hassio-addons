#!/usr/bin/env bashio

CONFIGLOCATION=$(bashio::config "CONFIG_LOCATION")

# Create directory
mkdir -p $CONFIGLOCATION/config

# Copy previous config if existing
if [ -d /data/config ]; then
  echo "Moving to new location $CONFIGLOCATION"
  mv /data/config/* $CONFIGLOCATION/config/
  rm -r /data/config
fi

# Make symlinks
ln -snf -T $CONFIGLOCATION/config /data

# Make sure permissions are right
chown -R $(id -u):$(id -g) $CONFIGLOCATION
