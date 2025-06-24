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
			if [ "$TYPE" = "config_location" ]; then
				[ -f "$FILE" ] && jq --arg variable "$CONFIGLOCATION" '.storage_path = $variable' "$FILE" | sponge "$FILE"
			fi
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
change_folders "$(bashio::config 'config_location')" "/share/resiliosync_config" "config_location"
change_folders "$(bashio::config 'data_location')" "/share/resiliosync" "data_location"
change_folders "$(bashio::config 'downloads_location')" "/share/resiliosync_downloads" "downloads_location"

if [[ ! -e "$(bashio::config 'config_location')"/sync.conf ]]; then
	cp /defaults/sync.conf "$(bashio::config 'config_location')"/sync.conf
fi

# Add directories to dir_whitelist if missing
DIRS_TO_ADD=("/backup" "/media" "/share" "/addons")
for CONFIG_FILE in "$(bashio::config 'config_location')/sync.conf" "/defaults/sync.conf"; do
    if [ -f "$CONFIG_FILE" ]; then
        echo "Checking dir_whitelist in $CONFIG_FILE"
        for DIR in "${DIRS_TO_ADD[@]}"; do
            if ! jq -e ".webui.dir_whitelist | index(\"$DIR\")" "$CONFIG_FILE" > /dev/null; then
                echo "Adding $DIR to dir_whitelist"
                jq ".webui.dir_whitelist += [\"$DIR\"]" "$CONFIG_FILE" | sponge "$CONFIG_FILE"
            fi
        done
    fi
done
