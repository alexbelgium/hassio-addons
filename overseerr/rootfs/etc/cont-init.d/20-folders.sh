#!/bin/bash

slug=overseerr
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

# shellcheck disable=SC2013
for file in $(grep -Esril "/config/.config/yarn" /usr /etc /defaults); do
    sed -i "s=/config/.config/yarn=/config/yarn=g" "$file"
done
yarn config set global-folder /config/yarn
chown -R "$PUID:$PGID" /config
