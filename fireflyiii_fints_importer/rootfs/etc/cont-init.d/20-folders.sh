#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE=$(dirname "$CONFIGSOURCE")

# Create directory
mkdir -p "$CONFIGSOURCE"

# Create symlinks
rm -r /data/configurations
ln -sf "$CONFIGSOURCE" /data/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
