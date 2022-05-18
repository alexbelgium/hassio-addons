#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#Disable script
echo "script is not enabled yet"
exit 0

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
DATALOCATION=$(bashio::config 'data_location')
if [[ "$DATALOCATION" = "null" || -z "$DATALOCATION" ]]; then DATALOCATION=/config/addons_config/${HOSTNAME#*-}; fi

# Check config location
LOCATION=$(bashio::config 'config_location')
if [[ "$CONFIGLOCATION" = "null" || -z "$CONFIGLOCATION" ]]; then CONFIGLOCATION=/config/addons_config/${HOSTNAME#*-}_config; fi


# Set data location
bashio::log.info "Setting data location to $LOCATION"
sed -i "s|/config|$LOCATION|g" /etc/services.d/jellyfin/run
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/10-adduser
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/30-config

echo "Creating $LOCATION"
mkdir -p "$LOCATION"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"


echo "Checking folders"
LOCATION="/share/resiliosync"
mkdir -p "$LOCATION"/folders
mkdir -p "$LOCATION"/mounted_folders
mkdir -p /share/resiliosync_config

echo "Checking permissions"
chown -R "$(id -u):$(id -g)" "$LOCATION"
