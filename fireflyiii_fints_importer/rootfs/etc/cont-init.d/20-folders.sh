#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE=$(dirname "$CONFIGSOURCE")

# Create directory
mkdir -p "$CONFIGSOURCE"

# If no file, provide example
[ ! "$(ls -A "${CONFIGSOURCE}")" ] && cp -rn /app/data/configurations/* "$CONFIGSOURCE"/

# Create symlinks
rm -r /app/data/configurations
ln -sf "$CONFIGSOURCE" /app/data/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
