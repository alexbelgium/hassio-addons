#!/usr/bin/env bashio

##################
# SYMLINK CONFIG #
##################

if [ ! -d /share/plex ]; then
    echo "Creating /share/plex"
    mkdir -p /share/plex
fi

if [ ! -d /share/plex/Library ] && [ -d /config/Library ]; then
    echo "moving Library folder"
    mv /config/Library /share/plex
else
    rm -r /config/Library
    echo "Using existing config"
fi
ln -sf /share/plex/Library /config

# Only fix ownership/mode if needed (top-level only—*not* blindly every file)
PUID="$(bashio::config "PUID")"
PGID="$(bashio::config "PGID")"
PUID="${PUID:-0}"
PGID="${PGID:-0}"

# Only run fixes if not root (UID/GID != 0)
if [ "$PUID" != "0" ] && [ "$PGID" != "0" ]; then
    WANTED_MODE="777"
    CURRENT_MODE=$(stat -c '%a' /share/plex)
    if [ "$CURRENT_MODE" != "$WANTED_MODE" ]; then
        bashio::log.warning "Providing adequate permissions, please wait"
        chown -R "$PUID:$PGID" /share/plex
        chmod -R 777 /share/plex
    fi
fi
