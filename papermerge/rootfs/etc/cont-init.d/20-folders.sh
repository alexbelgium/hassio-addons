#!/usr/bin/env bashio

CONFIGLOCATION=$(bashio::config "CONFIG_LOCATION")

# Create directory
mkdir -p $CONFIGLOCATION/config

# Copy previous config if existing
unlink /data/config 2>/dev/null || true
if [ -d /data/config ]; then
  echo "Moving to new location $CONFIGLOCATION"
  mv /data/config/* $CONFIGLOCATION/config/
  rm -r /data/config
fi

# Make symlinks
ln -s $CONFIGLOCATION/config /data/config

# Make sure permissions are right
chown -R $(id -u):$(id -g) $CONFIGLOCATION
