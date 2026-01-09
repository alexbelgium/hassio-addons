#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=wger
legacy_path="/homeassistant/addons_config/$slug"
target_path="/config"

mkdir -p "$target_path"

if bashio::config.has_value 'CONFIG_LOCATION' && [ "$(bashio::config 'CONFIG_LOCATION')" != "/config" ]; then
    legacy_path="$(bashio::config 'CONFIG_LOCATION')"
fi

if [ -d "$legacy_path" ]; then
    if [ ! -f "$legacy_path/.migrated" ] || [ -z "$(ls -A "$target_path" 2>/dev/null)" ]; then
        echo "Migrating $legacy_path to $target_path"
        cp -rnf "$legacy_path"/. "$target_path"/ || true
        touch "$legacy_path/.migrated"
    fi
fi
