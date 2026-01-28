#!/usr/bin/env bashio

##################
# SYMLINK CONFIG #
##################

DATA_LOCATION="$(bashio::config 'data_location')"
OLD_LOCATION=""

if [ -L /config/Library ]; then
    old_library_path="$(readlink -f /config/Library)"
    if [ -n "$old_library_path" ]; then
        OLD_LOCATION="$(dirname "$old_library_path")"
    fi
fi

if [ -z "$OLD_LOCATION" ] && [ -d "/share/plex" ]; then
    OLD_LOCATION="/share/plex"
fi

if [ -n "$OLD_LOCATION" ] && [ "$DATA_LOCATION" != "$OLD_LOCATION" ] && [ -d "$OLD_LOCATION" ]; then
    if [ -d "${DATA_LOCATION}" ] && [ "$(ls -A "${DATA_LOCATION}" 2>/dev/null)" ]; then
        echo "Skipping migration: ${DATA_LOCATION} already contains data"
    else
        echo "Migrating existing ${OLD_LOCATION} data to ${DATA_LOCATION}"
        mkdir -p "${DATA_LOCATION}"
        cp -a "${OLD_LOCATION}/." "${DATA_LOCATION}/" || true
    fi
fi

if [ ! -d "${DATA_LOCATION}" ]; then
    echo "Creating ${DATA_LOCATION}"
    mkdir -p "${DATA_LOCATION}"
fi

if [ ! -d "${DATA_LOCATION}/Library" ]; then
    echo "moving Library folder"
    mv /config/Library "${DATA_LOCATION}"
    ln -s "${DATA_LOCATION}/Library" /config
    echo "links done"
else
    rm -r /config/Library
    ln -s "${DATA_LOCATION}/Library" /config
    echo "Using existing config"
fi

# Adapt permissions if needed
if ! bashio::config.true "skip_permissions_check" && [ "${PUID:-0}" != "0" ] && [ "${PGID:-0}" != "0" ]; then
    bashio::log.info "Updating permissions"
    chown -R "$PUID:$PGID" "${DATA_LOCATION}"
    chmod -R 777 "${DATA_LOCATION}"
fi
