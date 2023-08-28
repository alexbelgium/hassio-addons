#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# DATA_LOCATION #
#################

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"

bashio::log.info "Setting data location"
DATA_LOCATION="$(bashio::config 'data_location')"
export IMMICH_MEDIA_LOCATION="$DATA_LOCATION"
if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "$DATA_LOCATION" > /var/run/s6/container_environment/IMMICH_MEDIA_LOCATION
fi
printf "%s" "IMMICH_MEDIA_LOCATION=\"$DATA_LOCATION\"" >> ~/.bashrc

echo "... check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "... setting permissions"
chown -R "$PUID":"$PGID" "$DATA_LOCATION"

echo "... correcting official script"
# shellcheck disable=SC2013
for file in $(grep -sril '/photos' /etc); do sed -i "s|/photos|$DATA_LOCATION|g" "$file"; done
if [ -f /photos ]; then rm -r /photos; fi
ln -sf "$DATA_LOCATION" /photos
chown -R "$PUID":"$PGID" /photos

mkdir -p "$MACHINE_LEARNING_CACHE_FOLDER" "$TYPESENSE_DATA_DIR"
