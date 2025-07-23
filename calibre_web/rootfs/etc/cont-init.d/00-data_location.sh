#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    # Default location
    LOCATION="/config"
else
    bashio::log.warning "Warning : a custom data location was selected, but the previous folder will NOT be copied. You need to do it manually"

    # Check if config is located in an acceptable location
    LOCATIONOK=""
    for location in "/share" "/config" "/data" "/mnt"; do
        if [[ "$LOCATION" == "$location"* ]]; then
            LOCATIONOK=true
        fi
    done

    if [ -z "$LOCATIONOK" ]; then
        LOCATION=/config
        bashio::log.fatal "Your data_location value can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $LOCATION"
    fi

fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"
sed -i "1a export HOME=$LOCATION" /etc/services.d/*/run
sed -i "1a export FM_HOME=$LOCATION" /etc/services.d/*/run
sed -i "s|/config|$LOCATION|g" /defaults/*
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/*
sed -i "s|/config|$LOCATION|g" /etc/services.d/*/run
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/FM_HOME; fi
printf "%s\n" "HOME=\"$LOCATION\"" >> ~/.bashrc
printf "%s\n" "FM_HOME=\"$LOCATION\"" >> ~/.bashrc

usermod --home "$LOCATION" abc

# Create folder
echo "Creating $LOCATION"
mkdir -p "$LOCATION"

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"
