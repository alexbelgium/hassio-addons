#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE=$(dirname "$CONFIGSOURCE")

# Create directory
mkdir -p "$CONFIGSOURCE" || true
mkdir -p "$CONFIGSOURCE/import_files" || true
mkdir -p "$CONFIGSOURCE/configurations" || true

# Create symlinks
cp -rnf /data/configurations "$CONFIGSOURCE"
rm -r /data/configurations
ln -s "$CONFIGSOURCE"/configurations /data

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
