#!/usr/bin/env bashio
# shellcheck shell=bash

set -euo pipefail

##################
# SYMLINK CONFIG #
##################

DATA_LOCATION="$(bashio::config 'data_location')"
OLD_LOCATION=""

is_populated() {
    local d="$1"
    [[ -d "$d" ]] || return 1

    # Treat default/placeholder dirs as "empty"
    # Use strong Plex indicators (adjust if your layout differs)
    [[ -f "${d}/Library/Application Support/Plex Media Server/Preferences.xml" ]] && return 0
    [[ -f "${d}/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" ]] && return 0
    return 1
}

if [[ -L /config/Library ]]; then
    old_library_path="$(readlink -f /config/Library || true)"
    if [[ -n "${old_library_path}" ]]; then
        OLD_LOCATION="$(dirname "${old_library_path}")"
    fi
fi

if [[ -z "${OLD_LOCATION}" && -d "/share/plex" ]]; then
    OLD_LOCATION="/share/plex"
fi

if [[ -n "${OLD_LOCATION}" && "${DATA_LOCATION}" != "${OLD_LOCATION}" && -d "${OLD_LOCATION}" ]]; then
    if is_populated "${DATA_LOCATION}"; then
        bashio::log.info "Skipping migration: ${DATA_LOCATION} already has Plex data"
    else
        bashio::log.warning "Migrating existing ${OLD_LOCATION} data to ${DATA_LOCATION}"
        mkdir -p "${DATA_LOCATION}"
        cp -a "${OLD_LOCATION}/." "${DATA_LOCATION}/"
    fi
fi

mkdir -p "${DATA_LOCATION}"

# Ensure /config/Library points to ${DATA_LOCATION}/Library
if [[ ! -d "${DATA_LOCATION}/Library" ]]; then
    bashio::log.info "Moving /config/Library to ${DATA_LOCATION}/Library"
    # If /config/Library is a symlink, don't mv it
    if [[ -L /config/Library ]]; then
        rm -f /config/Library
        mkdir -p "${DATA_LOCATION}/Library"
    elif [[ -d /config/Library ]]; then
        mv /config/Library "${DATA_LOCATION}/Library"
    else
        mkdir -p "${DATA_LOCATION}/Library"
    fi
fi

# Replace /config/Library with a symlink (safe handling)
if [[ -e /config/Library && ! -L /config/Library ]]; then
    # At this point it should be absent or already moved; if it still exists as a directory, don't delete blindly
    bashio::log.warning "/config/Library exists and is not a symlink; leaving it in place to avoid data loss"
else
    rm -f /config/Library || true
    ln -s "${DATA_LOCATION}/Library" /config/Library
fi

# Adapt permissions if needed
if ! bashio::config.true "skip_permissions_check" && [[ "${PUID:-0}" != "0" && "${PGID:-0}" != "0" ]]; then
    bashio::log.info "Updating permissions"
    chown -R "$PUID:$PGID" "${DATA_LOCATION}"
    chmod -R u+rwX,go+rX,go-w "${DATA_LOCATION}"
fi
