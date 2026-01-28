#!/usr/bin/env bashio

##################
# SYMLINK CONFIG #
##################

DATA_LOCATION="$(bashio::config 'data_location')"

echo "Database stored in ${DATA_LOCATION}"

if [ ! -d "${DATA_LOCATION}/Plex Media Server" ]; then
    echo "... creating ${DATA_LOCATION}/Plex Media Server"
    mkdir -p "${DATA_LOCATION}/Plex Media Server"
fi

if [ -d "/config/Library/Application Support/Plex Media Server" ]; then
    echo "... creating /symlink"
    rm -r "/config/Library/Application Support/*"
    ln -s "${DATA_LOCATION}/Plex Media Server" "/config/Library/Application Support"
fi

if [ ! -d "/config/Library/Application Support" ]; then
    echo "... creating /symlink"
    mkdir -p "/config/Library/Application Support"
    ln -s "${DATA_LOCATION}/Plex Media Server" "/config/Library/Application Support"
fi

# Adapt permissions if needed
if ! bashio::config.true "skip_permissions_check" && [ "${PUID:-0}" != "0" ] && [ "${PGID:-0}" != "0" ]; then
    echo "... setting permissions, this might take a long time. If it takes too long at each boot, you could instead activate skip_permissions_check in the addon options"
    chmod -R 755 "${DATA_LOCATION}"
    chown -R "$PUID:$PGID" "${DATA_LOCATION}"
elif bashio::config.true "skip_permissions_check"; then
    bashio::log.warning "... skipping permissions check as 'skip_permissions_check' is set"
fi

# Clear Codecs folder if checked
if bashio::config.true "clear_codecs_folder" && [[ -d "${DATA_LOCATION}/Plex Media Server/Codecs" ]]; then
    echo "... deleting codecs folder"
    rm -r "${DATA_LOCATION}/Plex Media Server/Codecs"
fi
