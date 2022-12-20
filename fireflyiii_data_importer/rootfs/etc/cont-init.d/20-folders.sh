#!/usr/bin/env bashio
# shellcheck shell=bash

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE=$(dirname "$CONFIGSOURCE")

# Create directory
mkdir -p "$CONFIGSOURCE" || true
mkdir -p "$CONFIGSOURCE/import_files" || true
mkdir -p "$CONFIGSOURCE/configurations" || true

# Make sure permissions are right
chown -R "root:root" "$CONFIGSOURCE"
chmod -R 755 "$CONFIGSOURCE"
