#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Migrate files #
#################
if [ -f /data/birdnet.db ]; then
    bashio::log.warning "Moving db to /config"
    mv /data/birdnet.db /config
fi

######################
# Birdsongs location #
######################

# Get current settings
CURRENT_BIRDSONGS_FOLDER="clips/"
if [ -f /config/config.yaml ]; then
    CURRENT_BIRDSONGS_FOLDER="$(yq '.realtime.audio.export.path' /config/config.yaml)"
    CURRENT_BIRDSONGS_FOLDER="${CURRENT_BIRDSONGS_FOLDER//\"/}"
fi
# If default, converts it to its default path
if [[ "$CURRENT_BIRDSONGS_FOLDER" == "clips/" ]]; then
    CURRENT_BIRDSONGS_FOLDER="/data/clips/"
fi

# Get new setting
BIRDSONGS_FOLDER="$(bashio::config "BIRDSONGS_FOLDER")"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER:-/config/clips}"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER%/}"
mkdir -p "$BIRDSONGS_FOLDER" || bashio::log.fatal "Warning, birdsongs folder $BIRDSONGS_FOLDER cannot be created"
bashio::log.info "... audio clips saved to $BIRDSONGS_FOLDER according to addon options"

# Migrate data if different
if [[ "$CURRENT_BIRDSONGS_FOLDER" != "$BIRDSONGS_FOLDER" ]]; then
    bashio::log.warning "The birdsongs folder was changed from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
    # Migrate files
    if [[ -d "$CURRENT_BIRDSONGS_FOLDER" ]] && [[ "$(ls -A "$CURRENT_BIRDSONGS_FOLDER")" ][; then
        bashio::log.warning "... audio clips found in $CURRENT_BIRDSONGS_FOLDER, migrating to $CURRENT_BIRDSONGS_FOLDER. Previous files will be kept in place with the folder renamed to $CURRENT_BIRDSONGS_FOLDER_migrated"
        cp -rnf "$CURRENT_BIRDSONGS_FOLDER"/* "$BIRDSONGS_FOLDER"/
        mv "$CURRENT_BIRDSONGS_FOLDER" "$CURRENT_BIRDSONGS_FOLDER"_migrated
    fi
    # Adapt config file
    echo "... adapting config.yaml"
    for configloc in /config/config.yaml /internal/conf/config.yaml; do
        if [ -f "$configloc" ]; then
            yq -i -y ".realtime.audio.export.path = \"$BIRDSONGS_FOLDER/\"" "$configloc"
        fi
    done
fi

####################
# Correct defaults #
####################
bashio::log.info "Correct config for defaults"

# Database location
echo "... database location is /config/birdnet.db"
for configloc in /config/config.yaml /internal/conf/config.yaml; do
    if [ -f "$configloc" ]; then
        yq -i -y ".output.sqlite.path = \"/config/birdnet.db\"" "$configloc"
    fi
done

# If default capture is set at 0%, increase it to 50%
current_volume="$(amixer sget Capture | grep -oP '\[\d+%]' | tr -d '[]%' | head -1)" 2>/dev/null || true
current_volume="${current_volume:-100}"
if [[ "$current_volume" -eq 0 ]]; then
    amixer sset Capture 70%
    bashio::log.warning "Microphone was off, volume set to 70%."
fi
