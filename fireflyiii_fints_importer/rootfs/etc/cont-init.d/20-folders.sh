#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE="/config/addons_config/fireflyiii_fints_importer"

# Create directory
mkdir -p "$CONFIGSOURCE"

# If no file, provide example
[ ! "$(ls -A "${CONFIGSOURCE}")" ] && cp -rn /app/configurations/* "$CONFIGSOURCE"/

# Create symlinks
rm -r /app/configurations
ln -sf "$CONFIGSOURCE" /app/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
