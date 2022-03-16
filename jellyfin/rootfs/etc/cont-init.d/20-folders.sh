#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

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
    chown -R abc:abc /jellyfin
fi

if [ ! -d "$LOCATION"/tv ]; then
    echo "Creating $LOCATION/tv"
    mkdir -p "$LOCATION"/tv
    chown -R abc:abc "$LOCATION"/tv
fi

if [ ! -d "$LOCATION"/movies ]; then
    echo "Creating $LOCATION/movies"
    mkdir -p "$LOCATION"/movies
    chown -R abc:abc "$LOCATION"/movies
fi

if [ ! -d "$LOCATION" ]; then
    echo "Creating $LOCATION"
    mkdir -p "$LOCATION"
    chown -R abc:abc "$LOCATION"
fi

# links

if [ ! -d /jellyfin/cache ]; then
    echo "Creating link for /jellyfin/cache"
    mkdir -p "$LOCATION"/cache
    chown -R abc:abc "$LOCATION"/cache
    ln -s "$LOCATION"/cache /jellyfin/cache
fi

if [ ! -d /jellyfin/data ]; then
    echo "Creating link for /jellyfin/data"
    mkdir -p "$LOCATION"/data
    chown -R abc:abc "$LOCATION"/data
    ln -s "$LOCATION"/data /jellyfin/data
fi

if [ ! -d /jellyfin/logs ]; then
    echo "Creating link for /jellyfin/logs"
    mkdir -p "$LOCATION"/logs
    chown -R abc:abc "$LOCATION"/logs
    ln -s "$LOCATION"/logs /jellyfin/logs
fi

if [ ! -d /jellyfin/metadata ]; then
    echo "Creating link for /jellyfin/metadata"
    mkdir -p "$LOCATION"/metadata
    chown -R abc:abc "$LOCATION"/metadata
    ln -s "$LOCATION"/metadata /jellyfin/metadata
fi

if [ ! -d /jellyfin/plugins ]; then
    echo "Creating link for /jellyfin/plugins"
    mkdir -p "$LOCATION"/plugins
    chown -R abc:abc "$LOCATION"/plugins
    ln -s "$LOCATION"/plugins /jellyfin/plugins
fi

if [ ! -d /jellyfin/root ]; then
    echo "Creating link for /jellyfin/root"
    mkdir -p "$LOCATION"/root
    chown -R abc:abc "$LOCATION"/root
    ln -s "$LOCATION"/root /jellyfin/root
fi
