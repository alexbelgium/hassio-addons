#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

LOCATION=$(bashio::config 'data_location')

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

# Set folders
if [ ! -d /jellyfin ]; then
    echo "Creating /jellyfin"
    mkdir -p /jellyfin
    chown -R "$PUID:$PGID" /jellyfin
fi

for folders in "tv" "movie"; do
    echo "Creating $LOCATION/$folders"
    mkdir -p "$LOCATION/$folders"
    chown -R "$PUID:$PGID" "$LOCATION/$folders"
done

# links in /data
for folders in "cache" "log" "data/metadata"; do
    echo "Creating link for /jellyfin/$folders"
    mkdir -p /data/"$folders"
    chown -R "$PUID:$PGID" /data/"$folders"
    rm -r "$LOCATION/$folders"
    mkdir -p "$LOCATION/$folders"
    ln -s /data/"$folders" "$LOCATION/$folders"
done
