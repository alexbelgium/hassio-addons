#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=photoprism
new_config_location="/config"
new_config_dir="$new_config_location"
mkdir -p "$new_config_dir"

if bashio::config.has_value "CONFIG_LOCATION" && [[ "$(bashio::config "CONFIG_LOCATION")" != "/config" ]]; then
    old_config_location="$(bashio::config "CONFIG_LOCATION")"
else
    old_config_location="/config/addons_config/photoprism/config.yaml"
fi
old_config_dir="$(dirname "$old_config_location")"

if [ "$old_config_dir" != "$new_config_dir" ] && [ -d "$old_config_dir" ]; then
    echo "Migrating $old_config_dir to /addon_configs/xxx-$slug"
    cp -rnf "$old_config_dir"/. "$new_config_dir"/ || true
    echo "Migrated to internal config folder accessible at /addon_configs/xxx-$slug" \
        > "$old_config_dir/.migrate"
fi

if [ "$old_config_location" != "$new_config_location" ]; then
    bashio::log.info "Updating CONFIG_LOCATION to $new_config_location"
    bashio::addon.option "CONFIG_LOCATION" "$new_config_location"
fi

if [ -d /config/addons_config ]; then
    rm -rf /config/addons_config
fi
