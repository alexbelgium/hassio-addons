#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

##########################
# MIGRATIONS AND UPDATES #
##########################

# Clean typesense
if [ -d /data/typesense ]; then
    rm -r /data/typesense
fi

#################
# DATA_LOCATION #
#################

if bashio::config.has_value "PUID"; then
    PUID="$(bashio::config 'PUID')"
else
    PUID=0
fi
if bashio::config.has_value "PGID"; then
    PGID="$(bashio::config 'PGID')"
else
    PGID=0
fi

bashio::log.info "Setting data location"
DATA_LOCATION="$(bashio::config 'data_location')"
export IMMICH_MEDIA_LOCATION="$DATA_LOCATION"
if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "$DATA_LOCATION" > /var/run/s6/container_environment/IMMICH_MEDIA_LOCATION
fi
printf "%s\n" "IMMICH_MEDIA_LOCATION=\"$DATA_LOCATION\"" >> ~/.bashrc

echo "... check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "... setting permissions"
chown -R "$PUID":"$PGID" "$DATA_LOCATION"

echo "... correcting official script"
# shellcheck disable=SC2013
for file in $(grep -sril '/photos' /etc); do sed -i "s|/photos|$DATA_LOCATION|g" "$file"; done
if [ -f /photos ]; then rm -r /photos; fi
ln -sf "$DATA_LOCATION" /photos
chown "$PUID":"$PGID" /photos

mkdir -p "$MACHINE_LEARNING_CACHE_FOLDER"
mkdir -p "$REVERSE_GEOCODING_DUMP_DIRECTORY"
chown -R "$PUID":"$PGID" "$MACHINE_LEARNING_CACHE_FOLDER"
chown -R "$PUID":"$PGID" "$REVERSE_GEOCODING_DUMP_DIRECTORY"
chown -R "$PUID":"$PGID" /data
chmod 777 /data

##################
# REDIS LOCATION #
##################

echo "sed -i \"s=/config/redis=/data/redis=g\" /etc/s6*/s6*/*/run" >> /docker-mods
echo "sed -i \"s=/config/log/redis=/data/log=g\" /etc/s6*/s6*/*/run" >> /docker-mods
mkdir -p /data/redis
mkdir -p /data/log
chmod 777 /data/redis
chmod 777 /data/log
