#!/usr/bin/env bashio

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Create directory
mkdir -p "$(dirname "${CONFIGSOURCE}")"
mkdir -p "$(dirname "${CONFIGSOURCE}/import_files")"
mkdir -p "$(dirname "${CONFIGSOURCE}/configurations")"

# Make sure permissions are right
chown -R $(id -u):$(id -g) "$(dirname "${CONFIGSOURCE}")"
