#!/usr/bin/env bashio

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Create directory
mkdir -p "$(dirname "${CONFIGSOURCE}")"

# Make sure permissions are right
chown -R $(id -u):$(id -g) "$(dirname "${CONFIGSOURCE}")"
