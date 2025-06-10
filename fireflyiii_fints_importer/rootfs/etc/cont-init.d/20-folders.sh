#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config/addons_config/fireflyiii_fints_importer"

# Create directory
mkdir -p "$CONFIGSOURCE"

# If no file, provide example
if [ ! "$(ls -A "${CONFIGSOURCE}")" ] && [ -f /data/configurations ]; then
  cp -r /data/configurations/* "$CONFIGSOURCE"/ || true
  rm -r /data/configurations
fi

if [ ! "$(ls -A "${CONFIGSOURCE}")" ] && [ -f /app/configurations ]; then
  cp -r /app/configurations/* "$CONFIGSOURCE"/ || true
  rm -r /app/configurations
fi

ln -sf "$CONFIGSOURCE" /data/configurations
mkdir -p /app
ln -sf "$CONFIGSOURCE" /app/configurations

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
