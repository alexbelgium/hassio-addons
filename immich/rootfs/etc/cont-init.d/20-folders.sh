#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# DATA_LOCATION #
#################

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"

bashio::log.info "Setting data location"
DATA_LOCATION="$(bashio::config 'data_location')"

echo "... check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "... setting permissions"
chown -R "$PUID":"$PGID" "$DATA_LOCATION"

echo "... correcting official script"
for file in $(grep -sril '/photos' /etc); do sed -i "s|/photos|$DATA_LOCATION|g" "$file"; done
rm -r /photos
ln -sf "$DATA_LOCATION" /photos
chown -R "$PUID":"$PGID" /photos
