#!/usr/bin/env bashio

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE=$(dirname $CONFIGSOURCE)

# Create directory
mkdir -p "$CONFIGSOURCE" || true
mkdir -p "$CONFIGSOURCE/import_files" || true
mkdir -p "$CONFIGSOURCE/configurations" || true

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
