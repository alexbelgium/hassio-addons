#!/usr/bin/env bashio

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

# Adapt permissions if needed
if ! bashio::config.true "skip_permissions_check" && [ "${PUID:-0}" != "0" ] && [ "${PGID:-0}" != "0" ]; then
    chown -R "$PUID:$PGID" /share/plex
    chmod -R 777 /share/plex
fi

# Clear Codecs folder if checked
if ! bashio::config.true "clear_codecs_folder"; then
    rm -rf /share/plex/Plex\ Media\ Server/Codecs
fi
