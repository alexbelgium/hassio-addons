#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if [ -d "$HOME"/BirdSongs/StreamData ]; then
    bashio::log.fatal "Container stopping, saving temporary files."

    # Stop the services in parallel
    if systemctl is-active --quiet birdnet_analysis; then
        bashio::log.info "Stopping birdnet_analysis service."
        systemctl stop birdnet_analysis &
    fi

    if systemctl is-active --quiet birdnet_recording; then
        bashio::log.info "Stopping birdnet_recording service."
        systemctl stop birdnet_recording &
    fi

    # Wait for both services to stop
    wait

    # Check if there are files in StreamData and move them to /data/StreamData
    mkdir -p /data/StreamData
    if [ "$(ls -A "$HOME"/BirdSongs/StreamData)" ]; then
        if mv -v "$HOME"/BirdSongs/StreamData/* /data/StreamData/; then
            bashio::log.info "Files successfully moved to /data/StreamData."
        else
            bashio::log.error "Failed to move files to /data/StreamData."
            exit 1
        fi
    fi

    bashio::log.info "... files safe, allowing container to stop."
else
    bashio::log.info "No StreamData directory to process."
fi
