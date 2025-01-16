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
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER:-/config/clips}"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER%/}"
if ! mkdir -p "$BIRDSONGS_FOLDER"; then
    bashio::log.fatal "Cannot create $BIRDSONGS_FOLDER."
    exit 1
fi
bashio::log.info "... audio clips saved to $BIRDSONGS_FOLDER according to addon options"

# Migrate data if the folder has changed
if [[ "$CURRENT_BIRDSONGS_FOLDER" != "$BIRDSONGS_FOLDER" ]]; then
    bashio::log.warning "Birdsongs folder changed from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
    if [[ -d "$CURRENT_BIRDSONGS_FOLDER" && "$(ls -A "$CURRENT_BIRDSONGS_FOLDER")" ]]; then
        bashio::log.warning "Migrating files from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
        cp -rnf "$CURRENT_BIRDSONGS_FOLDER"/* "$BIRDSONGS_FOLDER"/
        mv "$CURRENT_BIRDSONGS_FOLDER" "${CURRENT_BIRDSONGS_FOLDER}_migrated"
    fi

    # Update config files with the new birdsongs folder path
    for configloc in "${CONFIG_LOCATIONS[@]}"; do
        if [ -f "$configloc" ]; then
            yq -i -y ".realtime.audio.export.path = \"$BIRDSONGS_FOLDER/\"" "$configloc"
        fi
    done
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
