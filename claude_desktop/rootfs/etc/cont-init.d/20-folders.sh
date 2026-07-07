#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=""

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    LOCATION="/config/data"
else
    LOCATIONOK=""
    for location in "/share" "/config" "/data" "/mnt"; do
        if [[ "$LOCATION" == "$location"* ]]; then
            LOCATIONOK=true
        fi
    done

    if [ -z "$LOCATIONOK" ]; then
        LOCATION="/config/data"
        bashio::log.fatal "Your data_location value can only be set in /share, /config, /data or /mnt. It will be reset to the default location : $LOCATION"
    fi
fi

bashio::log.info "Setting data location to $LOCATION"

for file in /etc/s6-overlay/s6-rc.d/*/run; do
    if [ "$(sed -n '1{/bash/p};q' "$file")" ] && ! grep -q '^export XDG_CACHE_HOME=/tmp/cache$' "$file"; then
        sed -i "1a export HOME=$LOCATION" "$file"
        sed -i "1a export FM_HOME=$LOCATION" "$file"
        sed -i "1a export XDG_CACHE_HOME=/tmp/cache" "$file"
    fi
done

for folders in /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d; do
    if [ -d "$folders" ]; then
        find "$folders" -type f -exec sed -i "s|/config/data|$LOCATION|g" {} + &> /dev/null || true
    fi
done

sed -i "s|^\(abc:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*|\1$LOCATION|" /etc/passwd

if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/FM_HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "/tmp/cache" > /var/run/s6/container_environment/XDG_CACHE_HOME; fi
grep -qxF "export HOME=\"$LOCATION\"" ~/.bashrc 2>/dev/null || {
    printf "%s\n" "export HOME=\"$LOCATION\""
    printf "%s\n" "export FM_HOME=\"$LOCATION\""
    printf "%s\n" "export XDG_CACHE_HOME=\"/tmp/cache\""
} >> ~/.bashrc

bashio::log.info "Creating $LOCATION"
mkdir -p "$LOCATION" /tmp/cache
chmod 755 /tmp/cache

if [ -e "$LOCATION/.cache" ] && [ ! -L "$LOCATION/.cache" ]; then
    rm -rf "$LOCATION/.cache"
fi
ln -sfn /tmp/cache "$LOCATION/.cache"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION" /tmp/cache
chmod -R 700 "$LOCATION"
