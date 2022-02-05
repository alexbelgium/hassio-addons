#!/usr/bin/env bashio

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Create directory
mkdir -p "$(dirname ${CONFIGSOURCE})" || true
mkdir -p "$(dirname ${CONFIGSOURCE}/import_files)" || true
mkdir -p "$(dirname ${CONFIGSOURCE}/configurations)" || true

# Make sure permissions are right
chown -R $(id -u):$(id -g) "$(dirname "${CONFIGSOURCE}")"
