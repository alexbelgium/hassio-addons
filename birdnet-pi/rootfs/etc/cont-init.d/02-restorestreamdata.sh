#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Check if there are files in "$HOME"/BirdSongs/StreamData and move them to /data/StreamData
if [ -d /data/StreamData ] && [ "$(ls -A /data/StreamData/)" ]; then

    bashio::log.warning "Container was stopped while files were still being analysed, restoring them"

    # Copy files
    if [ "$(ls -A /data/StreamData)" ]; then
        mv -v /data/StreamData/* "$HOME"/BirdSongs/StreamData/
    fi
    echo "... done"
    echo ""

    # Setting permissions
    chown -R pi:pi "$HOME"/BirdSongs

    # Cleaning folder
    rm -r /data/StreamData

fi

