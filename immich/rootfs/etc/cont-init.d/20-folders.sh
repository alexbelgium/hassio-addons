#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

######################
# GENERAL PARAMETERS #
######################

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

bashio::log.info "Setting data location"
DATA_LOCATION="$(bashio::config 'data_location')"
export IMMICH_MEDIA_LOCATION="$DATA_LOCATION"
if [ -d /var/run/s6/container_environment ]; then
	printf "%s" "$DATA_LOCATION" >/var/run/s6/container_environment/IMMICH_MEDIA_LOCATION
fi
printf "%s\n" "IMMICH_MEDIA_LOCATION=\"$DATA_LOCATION\"" >>~/.bashrc

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

####################
# LIBRARY LOCATION #
####################

if bashio::config.has_value "library_location"; then
	LIBRARY_LOCATION="$(bashio::config 'library_location')"
	bashio::log.info "Setting library location to $LIBRARY_LOCATION. This will not move any of your files, you'll need to do this manually"
	mkdir -p "$LIBRARY_LOCATION"
	chown -R "$PUID":"$PGID" "$LIBRARY_LOCATION"

	# Check if the existing library is a directory and not a symlink and has contents
	if [ -d "$DATA_LOCATION/library" ] && [ ! -L "$DATA_LOCATION/library" ] && [ "$(ls -A "$DATA_LOCATION/library")" ]; then
		bashio::log.yellow "-------------------------------"
		bashio::log.warning "Library folder in $DATA_LOCATION/library already exists, is a real folder, and is not empty. Moving to $DATA_LOCATION/library_old"
		bashio::log.yellow "-------------------------------"
		mv "$DATA_LOCATION/library" "$DATA_LOCATION/library_old"
		sleep 5
	fi

	# Create symbolic link only if it doesn't already exist or is incorrect
	if [ ! -L "$DATA_LOCATION/library" ] || [ "$(readlink -f "$DATA_LOCATION/library")" != "$LIBRARY_LOCATION" ]; then
		ln -sf "$LIBRARY_LOCATION" "$DATA_LOCATION/library"
	fi
fi

##################
# REDIS LOCATION #
##################

echo "sed -i \"s=/config/redis=/data/redis=g\" /etc/s6*/s6*/*/run" >>/docker-mods
echo "sed -i \"s=/config/log/redis=/data/log=g\" /etc/s6*/s6*/*/run" >>/docker-mods
mkdir -p /data/redis
mkdir -p /data/log
chmod 777 /data/redis
chmod 777 /data/log
