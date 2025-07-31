#!/bin/bash
set -e

##################
# SYMLINK CONFIG #
##################

echo "Database stored in /share/plex"

if [ ! -d "/share/plex/Plex Media Server" ]; then
    echo "... creating /share/plex/Plex Media Server"
    mkdir -p "/share/plex/Plex Media Server"
fi

if [ -d "/config/Library/Application Support/Plex Media Server" ]; then
    echo "... creating /symlink"
    rm -r "/config/Library/Application Support/*"
    ln -s "/share/plex/Plex Media Server" "/config/Library/Application Support"
fi

if [ ! -d "/config/Library/Application Support" ]; then
    echo "... creating /symlink"
    mkdir -p "/config/Library/Application Support"
    ln -s "/share/plex/Plex Media Server" "/config/Library/Application Support"
fi

chown -R "$PUID:$PGID" /share/plex
