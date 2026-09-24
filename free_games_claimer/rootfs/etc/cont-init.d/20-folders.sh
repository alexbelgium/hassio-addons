#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define home
# Creating config location
echo "Creating config location ..."
HOME="$(bashio::config "CONFIG_LOCATION")"
HOME="$(dirname "$HOME")"
mkdir -p "$HOME"

# Up to version 2.1.1 the application stored its data in the add-on's private
# /data volume, which is only reachable with "docker exec". It now lives in
# /config/data, which Home Assistant exposes as
# /addon_configs/xxx-free_games_claimer/data. Copy an existing payload over
# once. The copy is staged and renamed into place, so an interrupted migration
# is retried on the next start instead of leaving a half-copied database or
# browser profile behind. Nothing is removed from /data, so downgrading still
# finds its data.
if [ ! -d /config/data ]; then
    legacy=()
    for entry in fgc.db fgc.db.pre-vogler-migration .vogler-remaster-migrated-v1.json \
        browser screenshots data prime-gaming.json; do
        if [ -e "/data/$entry" ]; then
            legacy+=("/data/$entry")
        fi
    done
    if [ "${#legacy[@]}" -gt 0 ]; then
        echo "Copying the application data to /config/data, this can take a few minutes ..."
        rm -rf /config/.data-migration
        mkdir -p /config/.data-migration
        cp -a "${legacy[@]}" /config/.data-migration/
        mv /config/.data-migration /config/data
    fi
fi

mkdir -p /config/data
