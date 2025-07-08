#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Config location
CONFIGLOCATION="$(bashio::config 'CONFIG_LOCATION')"

# Text
bashio::log.info "Setting config location to $CONFIGLOCATION"

# Adapt files
sed -i "s|/data/config|$CONFIGLOCATION|g" /etc/cont-init.d/*

# Avoid tamper issues
chown -R root:root "$CONFIGLOCATION"/custom*
