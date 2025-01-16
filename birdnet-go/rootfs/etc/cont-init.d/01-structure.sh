#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Required Commands
for cmd in yq amixer; do
    command -v "$cmd" >/dev/null 2>&1 || { bashio::log.fatal "$cmd is required but not installed. Exiting."; exit 1; }
done
	
# Default Variables
DEFAULT_BIRDSONGS_FOLDER="/data/clips/"
CONFIG_LOCATIONS=("/config/config.yaml" "/internal/conf/config.yaml")

# Database location
bashio::log.info "Setting database location to /config/birdnet.db"
for configloc in "${CONFIG_LOCATIONS[@]}"; do
    if [ -f "$configloc" ]; then
        yq -i -y ".output.sqlite.path = \"/config/birdnet.db\"" "$configloc"
        bashio::log.info "Updated database path in $configloc"
    fi
done

# Migrate Database
if [ -f /data/birdnet.db ]; then
    bashio::log.warning "Moving db to /config"
    mv /data/birdnet.db /config
fi

# Birdsongs Folder
CURRENT_BIRDSONGS_FOLDER="clips/"
for configloc in "${CONFIG_LOCATIONS[@]}"; do
    if [ -f "$configloc" ]; then
        CURRENT_BIRDSONGS_FOLDER="$(yq '.realtime.audio.export.path' "$configloc" | tr -d '\"')"
        break
    fi
done
CURRENT_BIRDSONGS_FOLDER="${CURRENT_BIRDSONGS_FOLDER:-$DEFAULT_BIRDSONGS_FOLDER}"

BIRDSONGS_FOLDER="$(bashio::config "BIRDSONGS_FOLDER")"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER:-/config/clips}"
BIRDSONGS_FOLDER="${BIRDSONGS_FOLDER%/}"
if ! mkdir -p "$BIRDSONGS_FOLDER"; then
    bashio::log.fatal "Cannot create $BIRDSONGS_FOLDER."
    exit 1
fi

# Volume Adjustment
current_volume="$(amixer sget Capture | grep -oP '\[\d+%\]' | tr -d '[]%' | head -1 2>/dev/null || echo "100")"
if [[ "$current_volume" -eq 0 ]]; then
    amixer sset Capture 70%
    bashio::log.warning "Microphone was off, volume set to 70%."
fi
