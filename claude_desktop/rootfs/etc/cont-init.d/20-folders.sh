#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Use the effective shared desktop user identity. In bypass mode an earlier init script may
# remap abc away from UID 0 because Claude Code rejects bypass permissions when run as root.
PUID=1000
PGID=1000

# Check data location
LOCATION="$(bashio::config 'data_location')"

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    LOCATION="/data/data"
else
    LOCATIONOK=""
    for location in "/share" "/config" "/data" "/mnt"; do
        if [[ "$LOCATION" == "$location"* ]]; then
            LOCATIONOK=true
        fi
    done

    if [ -z "$LOCATIONOK" ]; then
        LOCATION="/data/data"
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
        find "$folders" -type f -exec sed -i "s|/data/data|$LOCATION|g" {} + &> /dev/null || true
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

# Pre-create the Selkies joystick log so the base image's "chmod 777 /tmp/selkies*"
# calls (in init-selkies-config and svc-de) never fail on an empty glob.
touch /tmp/selkies_js.log
chmod 777 /tmp/selkies_js.log

if [ -e "$LOCATION/.cache" ] && [ ! -L "$LOCATION/.cache" ]; then
    rm -rf "$LOCATION/.cache"
fi
ln -sfn /tmp/cache "$LOCATION/.cache"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION" /tmp/cache "$XDG_RUNTIME_DIR" /data
chmod -R 700 "$LOCATION"

# The base init-selkies-config script overrides XDG_RUNTIME_DIR to $HOME/.XDG, which lands
# on persistent storage and conflicts with the tmpfs runtime dir set above. Re-assert the
# tmpfs value at the end of that oneshot so the app and desktop agree on one valid dir.
SELKIES_CONFIG_RUN="/etc/s6-overlay/s6-rc.d/init-selkies-config/run"
if [ -f "$SELKIES_CONFIG_RUN" ]; then
    sed -i '/^# XDG_RUNTIME_DIR override reconciled$/,+1d' "$SELKIES_CONFIG_RUN"
    printf '\n# XDG_RUNTIME_DIR override reconciled\nprintf "%%s" "%s" > /run/s6/container_environment/XDG_RUNTIME_DIR\n' "$XDG_RUNTIME_DIR" >> "$SELKIES_CONFIG_RUN"
fi

# The Selkies desktop init oneshots do best-effort device/permission setup (mknod
# /dev/input/*, chmod /tmp/selkies*, /dev/dri perms) that is only partially permitted in the
# HA add-on sandbox. A non-zero exit from a oneshot fails add-on bringup and crash-loops the
# container, so make these two tolerant and always report success. Longruns (svc-*) are left
# untouched so s6 keeps supervising them with their real exit codes.
for oneshot in init-video init-selkies-config; do
    run="/etc/s6-overlay/s6-rc.d/$oneshot/run"
    if [ -f "$run" ] && ! grep -q '^set +e$' "$run"; then
        sed -i "1a set +e" "$run"
        printf '\nexit 0\n' >> "$run"
    fi
done
