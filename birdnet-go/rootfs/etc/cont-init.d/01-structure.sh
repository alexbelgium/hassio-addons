#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Ensure required commands are installed
for cmd in yq amixer; do
    command -v "$cmd" >/dev/null 2>&1 || { bashio::log.fatal "$cmd is required but not installed. Exiting."; exit 1; }
done

# Default Variables
DEFAULT_BIRDSONGS_FOLDER="/data/clips/"
CONFIG_LOCATIONS=("/config/config.yaml" "/internal/conf/config.yaml")

#################
# Migrate Database
#################
if [ -f /data/birdnet.db ]; then
    bashio::log.warning "Moving birdnet.db to /config/birdnet.db"
    mv /data/birdnet.db /config
fi

######################
# Birdsongs Location
######################
CURRENT_BIRDSONGS_FOLDER="clips/"
# Read the current folder from config files
for configloc in "${CONFIG_LOCATIONS[@]}"; do
    if [ -f "$configloc" ]; then
        CURRENT_BIRDSONGS_FOLDER="$(yq '.realtime.audio.export.path' "$configloc" | tr -d '\"')"
        break
    fi
done
CURRENT_BIRDSONGS_FOLDER="${CURRENT_BIRDSONGS_FOLDER:-$DEFAULT_BIRDSONGS_FOLDER}"

# Adjust default path if it matches the default string
if [[ "$CURRENT_BIRDSONGS_FOLDER" == "clips/" ]]; then
    CURRENT_BIRDSONGS_FOLDER="$DEFAULT_BIRDSONGS_FOLDER"
fi

# Set the new birdsongs folder
BIRDSONGS_FOLDER="$(bashio::config "BIRDSONGS_FOLDER")"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER:-clips/}"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER%/}"  # Remove trailing slash if present
if [[ ! "$BIRDSONGS_FOLDER" == /* ]]; then
    if [ ! -d "/config/$BIRDSONGS_FOLDER" ]; then
        mkdir -p "/config/$BIRDSONGS_FOLDER"
    fi
    if [ -d "/data/$BIRDSONGS_FOLDER" ]; then
        if [ -n "$(ls -A /data/"$BIRDSONGS_FOLDER" 2>/dev/null)" ]; then
            cp -rf /data/"$BIRDSONGS_FOLDER"/* "/config/$BIRDSONGS_FOLDER"/
        fi
        rm -r "/data/$BIRDSONGS_FOLDER"
    fi
    ln -sf "/config/$BIRDSONGS_FOLDER" "/data/$BIRDSONGS_FOLDER"
fi

bashio::log.info "... audio clips saved to $BIRDSONGS_FOLDER according to addon options"

# Migrate data if the folder has changed
if [[ "${CURRENT_BIRDSONGS_FOLDER%/}" != "${BIRDSONGS_FOLDER%/}" ]]; then
    bashio::log.warning "Birdsongs folder changed from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
    # Update config files with the new birdsongs folder path
    for configloc in "${CONFIG_LOCATIONS[@]}"; do
        if [ -f "$configloc" ]; then
            yq -i -y ".realtime.audio.export.path = \"$BIRDSONGS_FOLDER/\"" "$configloc"
        fi
    done
    # Move files only if sqlite paths changed
    if [[ -d "$CURRENT_BIRDSONGS_FOLDER" && "$(ls -A "$CURRENT_BIRDSONGS_FOLDER")" ]]; then
        bashio::log.warning "Migrating files from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
        cp -rnf "$CURRENT_BIRDSONGS_FOLDER"/* "$BIRDSONGS_FOLDER"/
        mv "${CURRENT_BIRDSONGS_FOLDER%/}" "${CURRENT_BIRDSONGS_FOLDER%/}_migrated"
    fi
    # Adapt the database
    if [ -f /config/birdnet.db ]; then
        # Prepare
        backup="$(date +%Y%m%d_%H%M%S)"
        bashio::log.warning "Modifying database paths from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER. A backup named birdnet.db_$backup will be created before"

        # Create backup
        if ! cp /config/birdnet.db "birdnet.db_$backup"; then
            bashio::log.error "Failed to create a backup of the database. Aborting path modification."
            exit 1
        fi

        # Execute the query using sqlite3
        SQL_QUERY="UPDATE notes SET clip_name = '${BIRDSONGS_FOLDER%/}/' || substr(clip_name, length('${CURRENT_BIRDSONGS_FOLDER%/}/') + 1) WHERE clip_name LIKE '${CURRENT_BIRDSONGS_FOLDER%/}/%';"
        
        if ! sqlite3 /config/birdnet.db "$SQL_QUERY"; then
            bashio::log.warning "An error occurred while updating the paths. The database backup will be restored."
            BACKUP_FILE="/config/birdnet.db_$(date +%Y%m%d_%H%M%S)"  # Make sure this matches the earlier backup filename
            if [ -f "$BACKUP_FILE" ]; then
                mv "$BACKUP_FILE" /config/birdnet.db
                bashio::log.info "The database backup has been restored."
            else
                bashio::log.error "Backup file not found! Manual intervention required."
            fi
        else
            echo "Paths have been successfully updated."
        fi
    fi
fi

####################
# Correct Defaults
####################
bashio::log.info "Correcting configuration for defaults"

# Update database location in config files
for configloc in "${CONFIG_LOCATIONS[@]}"; do
    if [ -f "$configloc" ]; then
        yq -i -y ".output.sqlite.path = \"/config/birdnet.db\"" "$configloc"
        bashio::log.info "... database is located in $configloc"
    fi
done

# Adjust microphone volume if needed
current_volume="$(amixer sget Capture | grep -oP '\[\d+%\]' | tr -d '[]%' | head -1 2>/dev/null || echo "100")"
if [[ "$current_volume" -eq 0 ]]; then
    amixer sset Capture 70%
    bashio::log.warning "Microphone was off, volume set to 70%."
fi
