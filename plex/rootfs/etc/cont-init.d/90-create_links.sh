#!/bin/bash

##################
# SYMLINK CONFIG #
##################

if [ ! -d /share/plex ]; then
    echo "Creating /share/plex"
    mkdir -p /share/plex
    chown -R abc:abc /share/plex
else
    chown -R abc:abc /share/plex
fi

if [ ! -d /share/plex/Library ]; then
    echo "moving Library folder"
    mv /config/Library /share/plex
    ln -s /share/plex/Library /config
    echo "links done"
else
    rm -r /config/Library
    ln -s /share/plex/Library /config
    echo "Using existing config"
fi
