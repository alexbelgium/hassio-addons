#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

LOCATION=$(bashio::config 'data_location')
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

create_link() {
    local target_dir="$1"
    local link_path="$2"

    mkdir -p "$target_dir"
    mkdir -p "$(dirname "$link_path")"

    if [ -L "$link_path" ]; then
        rm "$link_path"
    elif [ -d "$link_path" ]; then
        cp -a "$link_path/." "$target_dir/" || true
        rm -r "$link_path"
    elif [ -e "$link_path" ]; then
        rm "$link_path"
    fi

    ln -sfn "$target_dir" "$link_path"
    chown -R "$PUID:$PGID" "$target_dir"
}

# Check if config is located in an acceptable location
LOCATIONOK=""
for location in "/share" "/config" "/data" "/mnt"; do
    if [[ "$LOCATION" == "$location"* ]]; then
        LOCATIONOK=true
    fi
done

if [ -z "$LOCATIONOK" ]; then
    LOCATION=/config/addons_config/${HOSTNAME#*-}
    bashio::log.fatal "Your data_location value can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $LOCATION"
fi

# Set folders

if [ ! -d /jellyfin ]; then
    echo "Creating /jellyfin"
    mkdir -p /jellyfin
    chown -R "$PUID:$PGID" /jellyfin
fi

if [ ! -d "$LOCATION"/tv ]; then
    echo "Creating $LOCATION/tv"
    mkdir -p "$LOCATION"/tv
    chown -R "$PUID:$PGID" "$LOCATION"/tv
fi

if [ ! -d "$LOCATION"/movies ]; then
    echo "Creating $LOCATION/movies"
    mkdir -p "$LOCATION"/movies
    chown -R "$PUID:$PGID" "$LOCATION"/movies
fi

if [ ! -d "$LOCATION" ]; then
    echo "Creating $LOCATION"
    mkdir -p "$LOCATION"
    chown -R "$PUID:$PGID" "$LOCATION"
fi

# links

echo "Creating link for /jellyfin/cache"
create_link "$LOCATION/cache" /jellyfin/cache

echo "Creating link for /jellyfin/data"
create_link "$LOCATION/data" /jellyfin/data

echo "Creating link for /jellyfin/log"
create_link "$LOCATION/log" /jellyfin/log

echo "Creating link for /jellyfin/metadata"
create_link "$LOCATION/metadata" /jellyfin/metadata

echo "Creating link for /jellyfin/plugins"
create_link "$LOCATION/plugins" /jellyfin/plugins

echo "Creating link for /jellyfin/root"
create_link "$LOCATION/root" /jellyfin/root

# Legacy mode
echo "Enable legacy mode"
create_link "$LOCATION" /config/addons_config/jellyfin
chown -R "$PUID:$PGID" "$LOCATION"
