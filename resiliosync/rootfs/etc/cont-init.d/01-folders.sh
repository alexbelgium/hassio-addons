#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# Define user #
###############

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

###################
# Create function #
###################

change_folders() {
	CONFIGLOCATION=$1
	ORIGINALLOCATION=$2
	TYPE=$3

	# Inform
	bashio::log.info "Setting $TYPE to $CONFIGLOCATION"

	if [ "$CONFIGLOCATION" != "$ORIGINALLOCATION" ]; then

		# Modify files
		echo "Adapting files"
		# shellcheck disable=SC2013,SC2086
		for file in $(grep -ril "$ORIGINALLOCATION" /etc /defaults); do sed -i "s=$ORIGINALLOCATION=$CONFIGLOCATION=g" $file; done

		# Adapt sync.conf
		for FILE in "$ORIGINALLOCATION/sync.conf" "$CONFIGLOCATION/sync.conf" "/defaults/sync.conf"; do
			if [ "$TYPE" = "data_location" ]; then
				[ -f "$FILE" ] && jq --arg variable "$CONFIGLOCATION" '.directory_root = $variable' "$FILE" | sponge "$FILE"
			fi
			if [ "$TYPE" = "downloads_location" ]; then
				[ -f "$FILE" ] && jq --arg variable "$CONFIGLOCATION" '.files_default_path = $variable' "$FILE" | sponge "$FILE"
			fi
		done

		# Transfer files
		if [ -d "$ORIGINALLOCATION" ] && [ "$(ls -A "$ORIGINALLOCATION" 2>/dev/null)" ]; then
			echo "Files were existing in $ORIGINALLOCATION, they will be moved to $CONFIGLOCATION"
			mv "$ORIGINALLOCATION"/* "$CONFIGLOCATION"/
			rmdir "$ORIGINALLOCATION"
		fi 2>/dev/null || true
	fi

	# Create folders
	echo "Checking if folders exist"
	for FOLDER in "$CONFIGLOCATION" "$CONFIGLOCATION"/folders "$CONFIGLOCATION"/mounted_folders "$CONFIGLOCATION"/downloads; do
		[ ! -d "$FOLDER" ] && echo "Creating $FOLDER" && mkdir -p "$FOLDER"
	done

	# Set permissions
	echo "Setting ownership to $PUID:$PGID"
	chown -R "$PUID":"$PGID" "$CONFIGLOCATION"
	chmod -R 777 "$CONFIGLOCATION"

}

########################
# Change data location #
########################

# Adapt files
change_folders "$(bashio::config 'data_location')" "/share/resiliosync" "data_location"
change_folders "$(bashio::config 'downloads_location')" "/share/resiliosync_downloads" "downloads_location"

# Ensure configuration is in /config
if [[ ! -e /config/sync.conf ]]; then
	cp /defaults/sync.conf /config/sync.conf
fi
jq '.storage_path = "/config"' /config/sync.conf | sponge /config/sync.conf
chown -R "$PUID":"$PGID" /config
chmod -R 777 /config

# Add directories to dir_whitelist if missing
DIRS_TO_ADD=("/backup" "/media" "/share" "/addons")
echo "Checking dir_whitelist in /config/sync.json"
for DIR in "${DIRS_TO_ADD[@]}"; do
	if ! jq -e ".webui.dir_whitelist | index(\"$DIR\")" /config/sync.json >/dev/null; then
		echo "Adding $DIR to dir_whitelist"
		jq ".webui.dir_whitelist += [\"$DIR\"]" /config/sync.json | sponge /config/sync.json
	fi
done
