#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION="/config/addons_config/changedetection.io"

# Check structure
mkdir -p "$LOCATION"
chown -R "$PUID":"$PGID" "$LOCATION"
chmod -R 755 "$LOCATION"
