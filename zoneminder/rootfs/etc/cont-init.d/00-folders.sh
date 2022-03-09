#!/usr/bin/env bashio
# shellcheck shell=bash

#CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
#CONFIGSOURCE=$(dirname "$CONFIGSOURCE")
CONFIGSOURCE="/config/addons_config/zoneminder"

cp -rn /configold/* "$CONFIGSOURCE"/

# Create directory
mkdir -p "$CONFIGSOURCE" || true

# Make sure permissions are right
chown -R "$(id -u):$(id -g)" "$CONFIGSOURCE"
