#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Check if there are files in /tmp/StreamData and move them to /data/StreamData
if [ -d /data/StreamData ] && [ "$(ls -A /tmp/StreamData)" ]; then

    bashio::log.warning "Container was stopped while files were still being analysed, restoring them"  

    # Copy files
    if [ "$(ls -A /data/StreamData)" ]; then
        mv /data/StreamData/* /tmp/StreamData/
    fi
    echo "... done"
    echo ""

    # Setting permissions
    chown -R pi:pi /tmp

    # Cleaning folder
    rm -r /data/StreamData

fi

