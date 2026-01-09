#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Set PUID PGID #
#################

# Get from options
PGID=$(bashio::config 'PGID')
PUID=$(bashio::config 'PUID')
# If blank, set 0
[[ "$PUID" = "null" ]] && PUID=0
[[ "$PGID" = "null" ]] && PGID=0
# Write in permission file
sed -i "1a PGID=$PGID" /etc/cont-init.d/01-setup-perms
sed -i "1a PUID=$PUID" /etc/cont-init.d/01-setup-perms
# Information
bashio::log.info "Setting PUID=$PUID, PGID=$PGID"

#####################
# Set Configuration #
#####################

cd /

# Config location
CONFIGLOCATION="/config"
legacy_path="/homeassistant/addons_config/tdarr"
target_path="$CONFIGLOCATION"

mkdir -p "$target_path"

# Use custom location for migration only if configured
if bashio::config.has_value 'CONFIG_LOCATION' && [ "$(bashio::config 'CONFIG_LOCATION')" != "/config" ]; then
    legacy_path="$(bashio::config 'CONFIG_LOCATION')"
fi

# Migrate legacy config
if [ -d "$legacy_path" ]; then
    if [ ! -f "$legacy_path/.migrated" ] || [ -z "$(ls -A "$target_path" 2>/dev/null)" ]; then
        echo "Migrating $legacy_path to $target_path"
        cp -rnf "$legacy_path"/. "$target_path"/ || true
        touch "$legacy_path/.migrated"
    fi
fi

# Create folder
mkdir -p "$CONFIGLOCATION"

# Rename base folder
mv /app /tdarr
sed -i "s|/app|/tdarr|g" /etc/cont-init.d/*
sed -i "s|/app|/tdarr|g" /etc/services.d/*/run

# Symlink configs
[ -d /tdarr/configs ] && rm -r /tdarr/configs
ln -s "$CONFIGLOCATION" /tdarr/configs

# Symlink server data
[ -d /tdarr/server/Tdarr ] && rm -r /tdarr/server/Tdarr
mkdir -p /tdarr/server
ln -s "$CONFIGLOCATION" /tdarr/server/Tdarr

# Text
bashio::log.info "Setting config location to $CONFIGLOCATION"
