#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if [ -d "$HOME"/BirdSongs/StreamData ]; then
    bashio::log.fatal "Container stopping, saving temporary files"

    # Stop the services in parallel
    systemctl stop birdnet_analysis &
    systemctl stop birdnet_recording

    # Ensure the target directory exists
    mkdir -p /data/StreamData

    # Use rsync to move files to /data/StreamData
    if [ "$(ls -A "$HOME"/BirdSongs/StreamData)" ]; then
        rsync -av --remove-source-files "$HOME"/BirdSongs/StreamData/ /data/StreamData/
    fi

    bashio::log.fatal "... files safe, allowing container to stop"
fi
