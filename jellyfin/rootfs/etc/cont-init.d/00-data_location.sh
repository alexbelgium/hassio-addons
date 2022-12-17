#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')
if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then LOCATION=/config/addons_config/${HOSTNAME#*-}; fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"
for file in $(grep -sril "/config" /etc /defaults); do sed -i "s=/config=$LOCATION=g" $file; done

echo "Creating $LOCATION"
mkdir -p "$LOCATION"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"
