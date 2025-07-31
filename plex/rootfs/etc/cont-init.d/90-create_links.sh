#!/usr/bin/env bashio

##################
# SYMLINK CONFIG #
##################

if [ ! -d /share/plex ]; then
    echo "Creating /share/plex"
    mkdir -p /share/plex
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

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"

if ! bashio::config.true "skip_permissions_check" && [ "${PUID:-0}" != "0" ] && [ "${PGID:-0}" != "0" ]; then
    chown -R "${PUID}:${PGID}" /share/plex
    chmod -R 777 /share/plex
fi
