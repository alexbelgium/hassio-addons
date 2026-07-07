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

# LinuxServer Selkies services expect the s6 envdir at /run/s6/container_environment.
# Home Assistant add-on startup can run without s6-overlay PID1, so create the envdir
# ourselves before those services start and before scripts write required variables.
S6_ENVDIR="/run/s6/container_environment"
mkdir -p "$S6_ENVDIR"
chmod 755 /run/s6 "$S6_ENVDIR"

XDG_RUNTIME_DIR="/run/user/$PUID"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

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

printf "%s" "$LOCATION" > "$S6_ENVDIR/HOME"
printf "%s" "$LOCATION" > "$S6_ENVDIR/FM_HOME"
printf "%s" "/tmp/cache" > "$S6_ENVDIR/XDG_CACHE_HOME"
printf "%s" "$XDG_RUNTIME_DIR" > "$S6_ENVDIR/XDG_RUNTIME_DIR"
grep -qxF "export HOME=\"$LOCATION\"" ~/.bashrc 2>/dev/null || {
    printf "%s\n" "export HOME=\"$LOCATION\""
    printf "%s\n" "export FM_HOME=\"$LOCATION\""
    printf "%s\n" "export XDG_CACHE_HOME=\"/tmp/cache\""
} >> ~/.bashrc

bashio::log.info "Creating $LOCATION"
mkdir -p "$LOCATION" /tmp/cache "$XDG_RUNTIME_DIR"
chmod 755 /tmp/cache
chmod 700 "$XDG_RUNTIME_DIR"

if [ -e "$LOCATION/.cache" ] && [ ! -L "$LOCATION/.cache" ]; then
    rm -rf "$LOCATION/.cache"
fi
ln -sfn /tmp/cache "$LOCATION/.cache"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION" /tmp/cache "$XDG_RUNTIME_DIR"
chmod -R 700 "$LOCATION"
