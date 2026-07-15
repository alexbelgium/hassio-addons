#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Align the shared desktop user (abc) with the configured PUID/PGID before any storage is
# chowned and before any service or s6-setuidgid call resolves abc. The base image's
# init-adduser applies the same remap, but it runs after cont-init, so doing it here first is
# what lets the tokensave/rtk/git setup in the 8x scripts run under the final identity.
PUID="$(if bashio::config.has_value 'PUID'; then bashio::config 'PUID'; else echo '1000'; fi)"
PGID="$(if bashio::config.has_value 'PGID'; then bashio::config 'PGID'; else echo '1000'; fi)"

# Claude Code refuses bypass-permissions mode under an effective root UID, so bypass mode
# always needs a non-root desktop user.
if [ "$(bashio::config 'permission_mode')" = "bypass" ] && [ "$PUID" -eq 0 ]; then
    bashio::log.warning "permission_mode: bypass cannot run Claude Code as root; using UID 1000 instead of the configured PUID 0"
    PUID=1000
fi

groupmod -o -g "$PGID" abc 2> /dev/null || true
usermod -o -u "$PUID" abc 2> /dev/null || true
if [ "$(id -u abc)" -ne "$PUID" ] || [ "$(id -g abc)" -ne "$PGID" ]; then
    PUID="$(id -u abc)"
    PGID="$(id -g abc)"
    bashio::log.warning "Unable to remap the abc desktop user; continuing with its current identity ${PUID}:${PGID}"
fi

# The base image's init-adduser reads PUID/PGID from the raw add-on options (default 0) and
# runs mid-startup, racing the services. Pin it to the effective identity chosen above so it
# can never remap abc away from the ownership applied below.
ADDUSER_RUN="/etc/s6-overlay/s6-rc.d/init-adduser/run"
if [ -f "$ADDUSER_RUN" ]; then
    sed -i "s|^PUID=.*|PUID=${PUID}|;s|^PGID=.*|PGID=${PGID}|" "$ADDUSER_RUN"
fi

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

# /tmp is a tmpfs and Xorg runs as the non-root abc user, which cannot create the X11 socket
# directory itself (_XSERVTransmkdir: euid != 0). Pre-create it with the standard sticky mode.
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Pre-create the Selkies joystick log so the base image's "chmod 777 /tmp/selkies*"
# calls (in init-selkies-config and svc-de) never fail on an empty glob.
touch /tmp/selkies_js.log
chmod 777 /tmp/selkies_js.log

if [ -e "$LOCATION/.cache" ] && [ ! -L "$LOCATION/.cache" ]; then
    rm -rf "$LOCATION/.cache"
fi
ln -sfn /tmp/cache "$LOCATION/.cache"

bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "${PUID}:${PGID}" "$LOCATION" /tmp/cache "$XDG_RUNTIME_DIR" /data
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
