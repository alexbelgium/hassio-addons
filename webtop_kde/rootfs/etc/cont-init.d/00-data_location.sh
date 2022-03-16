#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    # Default location
    LOCATION="/share/webtop_kde"
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
        LOCATION=/config/addons_config/${HOSTNAME#*-}
        bashio::log.fatal "Your data_location value can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $LOCATION"
    fi

fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"
sed -i "1a export HOME=$LOCATION" /etc/services.d/web/run
sed -i "1a export FM_HOME=$LOCATION" /etc/services.d/web/run
sed -i "s|/share/webtop_kde|$LOCATION|g" /defaults/*
sed -i "s|/share/webtop_kde|$LOCATION|g" /etc/cont-init.d/*
sed -i "s|/share/webtop_kde|$LOCATION|g" /etc/services.d/*/run
usermod --home "$LOCATION" abc

# Create folder
echo "Creating $LOCATION"
mkdir -p "$LOCATION"

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"
