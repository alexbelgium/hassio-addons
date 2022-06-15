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
sed -i "s|/config|$LOCATION|g" /etc/services.d/jellyfin/run
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/10-adduser
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/30-config

echo "Creating $LOCATION"
mkdir -p "$LOCATION"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"
