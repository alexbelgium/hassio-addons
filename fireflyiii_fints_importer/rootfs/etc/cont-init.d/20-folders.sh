#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE="/config/addons_config/fireflyiii_fints_importer"

# Create directory
mkdir -p "$CONFIGSOURCE"

# If no file, provide example
[ ! "$(ls -A "${CONFIGSOURCE}")" ] && cp -r /data/configurations/* "$CONFIGSOURCE"/

# Create symlinks
rm -r /data/configurations
ln -sf "$CONFIGSOURCE" /data/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
