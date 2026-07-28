#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Shared by every Selkies-based add-on in this repo (claude_desktop, webtop, webtop_kde) via a
# symlink; keep it add-on agnostic. The only per-add-on input is the home directory baked into
# the image by the Dockerfile's `usermod --home <dir> abc`, read back below.

# Default data location for this image: whatever the Dockerfile set as abc's home.
#
# Cached in a marker file rather than read from /etc/passwd on every boot, because this script
# rewrites that entry further down to the *selected* location. On a restart that reuses the
# container's writable layer, re-reading /etc/passwd would hand back the previous selection as
# the "image default", so clearing data_location would strand the user on their old custom path
# instead of restoring the built-in one. The marker shares its lifetime with the /etc/passwd
# edit it compensates for: both live in the writable layer, so a rebuilt or recreated container
# starts from a pristine /etc/passwd and regenerates the marker correctly.
#
# The `|| true` is load-bearing: getent exits 2 when the user does not exist, and under bashio's
# `set -o pipefail` plus this script's `set -e` that aborts the script at the assignment, before
# the fallback below can run. Same trap documented in 21-gpu_permissions.sh.
DEFAULT_LOCATION_MARKER="/etc/.addon_image_home"
if [ ! -s "$DEFAULT_LOCATION_MARKER" ]; then
    getent passwd abc 2> /dev/null | cut -d: -f6 > "$DEFAULT_LOCATION_MARKER" || true
fi
DEFAULT_LOCATION="$(cat "$DEFAULT_LOCATION_MARKER" 2> /dev/null || true)"
if [[ -z "$DEFAULT_LOCATION" || "$DEFAULT_LOCATION" == "/" ]]; then
    DEFAULT_LOCATION="/config/data"
    bashio::log.warning "Could not read the abc home directory from /etc/passwd; defaulting to $DEFAULT_LOCATION"
fi

# Align the shared desktop user (abc) with the configured PUID/PGID before any storage is
# chowned and before any service or s6-setuidgid call resolves abc. The base image's
# init-adduser applies the same remap, but it runs after cont-init, so doing it here first is
# what lets the tokensave/rtk/git setup in the 8x scripts run under the final identity.
PUID="$(if bashio::config.has_value 'PUID'; then bashio::config 'PUID'; else echo '1000'; fi)"
PGID="$(if bashio::config.has_value 'PGID'; then bashio::config 'PGID'; else echo '1000'; fi)"

# Claude Code refuses bypass-permissions mode under an effective root UID, so bypass mode
# always needs a non-root desktop user. Add-ons without a permission_mode option skip this.
if bashio::config.has_value 'permission_mode' && [ "$(bashio::config 'permission_mode')" = "bypass" ] && [ "$PUID" -eq 0 ]; then
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
    LOCATION="$DEFAULT_LOCATION"
else
    LOCATIONOK=""
    for location in "/share" "/config" "/data" "/mnt"; do
        if [[ "$LOCATION" == "$location"* ]]; then
            LOCATIONOK=true
        fi
    done

    if [ -z "$LOCATIONOK" ]; then
        LOCATION="$DEFAULT_LOCATION"
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

# Must agree with the CWS substitution in 90-ingress.sh: nginx proxies the Selkies data
# websocket to this port, and Selkies only listens on it if CUSTOM_WS_PORT reaches its process.
# Validated here, once, because the value goes on to be interpolated into generated shell and
# into a sed replacement in 90-ingress.sh, both of which take the normalised value back out of
# the envdir written below.
SELKIES_WS_PORT="${CUSTOM_WS_PORT:-8082}"
if ! [[ "$SELKIES_WS_PORT" =~ ^[0-9]+$ ]] || [ "$SELKIES_WS_PORT" -lt 1 ] || [ "$SELKIES_WS_PORT" -gt 65535 ]; then
    bashio::log.warning "CUSTOM_WS_PORT '${CUSTOM_WS_PORT:-}' is not a valid port number; using 8082"
    SELKIES_WS_PORT=8082
fi

# Upstream relies on s6-rc ordering: init-selkies-config publishes XDG_RUNTIME_DIR and
# CUSTOM_WS_PORT into the s6 envdir, and svc-selkies is started afterwards. The add-on
# entrypoint replaces s6-overlay and launches every s6-rc.d run script in parallel, with no
# dependency graph, so a longrun can snapshot the envdir (with-contenv reads it once, at exec)
# before the oneshot has written to it. Selkies is where that shows: it comes up with
# CUSTOM_WS_PORT unset and binds its data websocket on the 8081 default while nginx proxies
# 8082, and on the PIXELFLUX_WAYLAND images it reaches the compositor with no XDG_RUNTIME_DIR
# and panics with `RuntimeDirNotSet` binding the Wayland socket.
#
# Exporting both inside the run scripts puts them in each process's own environment, where no
# start ordering can lose them, and keeps every service agreeing on one runtime dir -- svc-de
# otherwise waits forever on a Wayland socket under a directory Selkies never used.

# Rewrite the home path baked into the image to the user-chosen one. No-op when data_location
# is left at its default. Runs before the exports below are injected, not after: this is a
# blind textual substitution, so a location *under* the image default (data_location
# /config/data_kde/foo against a /config/data_kde image) would otherwise rewrite the freshly
# injected "export HOME=/config/data_kde/foo" into ".../foo/foo".
if [ "$LOCATION" != "$DEFAULT_LOCATION" ]; then
    for folders in /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d; do
        if [ -d "$folders" ]; then
            find "$folders" -type f -exec sed -i "s|$DEFAULT_LOCATION|$LOCATION|g" {} + &> /dev/null || true
        fi
    done
fi

# Re-derived on every boot rather than injected once behind a marker, for the same reason the
# ~/.bashrc block below is: the run scripts live in the writable layer and survive a restart, so
# a write-once injection pins whatever PUID and CUSTOM_WS_PORT were in force the first time.
# Raising PUID would leave every service exporting a /run/user/<old-uid> the remapped abc user
# cannot use, and clearing a custom CUSTOM_WS_PORT would leave Selkies on the old port while
# 90-ingress.sh moved nginx back to 8082. Strip whatever a previous boot left -- the marked
# block, or the bare exports earlier versions wrote -- then write the current values. No
# upstream run script in these images sets any of these five, so the bare-line sweep only ever
# removes our own.
ENV_BLOCK_BEGIN="# --- BEGIN ADDON ENV (managed) ---"
ENV_BLOCK_END="# --- END ADDON ENV (managed) ---"
for file in /etc/s6-overlay/s6-rc.d/*/run; do
    [ -n "$(sed -n '1{/bash/p};q' "$file")" ] || continue
    sed -i "/^${ENV_BLOCK_BEGIN}\$/,/^${ENV_BLOCK_END}\$/d" "$file"
    sed -i -E '/^export (HOME|FM_HOME|XDG_CACHE_HOME|XDG_RUNTIME_DIR|CUSTOM_WS_PORT)=/d' "$file"
    # Each "1a" lands at line 2 and pushes the previous one down, so this reads bottom-up.
    sed -i "1a $ENV_BLOCK_END" "$file"
    sed -i "1a export HOME=\"$LOCATION\"" "$file"
    sed -i "1a export FM_HOME=\"$LOCATION\"" "$file"
    sed -i "1a export XDG_CACHE_HOME=\"/tmp/cache\"" "$file"
    sed -i "1a export XDG_RUNTIME_DIR=\"$XDG_RUNTIME_DIR\"" "$file"
    sed -i "1a export CUSTOM_WS_PORT=\"$SELKIES_WS_PORT\"" "$file"
    sed -i "1a $ENV_BLOCK_BEGIN" "$file"
done

sed -i "s|^\(abc:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*|\1$LOCATION|" /etc/passwd

printf "%s" "$LOCATION" > "$S6_ENVDIR/HOME"
printf "%s" "$LOCATION" > "$S6_ENVDIR/FM_HOME"
printf "%s" "/tmp/cache" > "$S6_ENVDIR/XDG_CACHE_HOME"
printf "%s" "$XDG_RUNTIME_DIR" > "$S6_ENVDIR/XDG_RUNTIME_DIR"
printf "%s" "$SELKIES_WS_PORT" > "$S6_ENVDIR/CUSTOM_WS_PORT"
# Re-derived on every boot rather than gated on a "does it already say $LOCATION" grep: that
# guard only ever recognized the CURRENT $LOCATION, so a user who changed data_location and
# later changed it back left two stale HOME/FM_HOME exports in ~/.bashrc, with the last one
# (not necessarily the correct one) winning for every interactive shell. The marker makes this
# idempotent regardless of how many times $LOCATION has changed: strip any previously managed
# block, then append one that reflects the current value.
BASHRC_HOME_BEGIN="# --- BEGIN ADDON HOME (managed) ---"
BASHRC_HOME_END="# --- END ADDON HOME (managed) ---"
if [ -f ~/.bashrc ]; then
    sed -i "/^${BASHRC_HOME_BEGIN}\$/,/^${BASHRC_HOME_END}\$/d" ~/.bashrc
fi
{
    printf "%s\n" "$BASHRC_HOME_BEGIN"
    printf "%s\n" "export HOME=\"$LOCATION\""
    printf "%s\n" "export FM_HOME=\"$LOCATION\""
    printf "%s\n" "export XDG_CACHE_HOME=\"/tmp/cache\""
    printf "%s\n" "$BASHRC_HOME_END"
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

# The base init-selkies-config script overrides XDG_RUNTIME_DIR to $HOME/.XDG, which lands on
# persistent storage and conflicts with the tmpfs runtime dir set above. Correct that write
# where it happens rather than re-asserting the value at the end of the oneshot: the tolerance
# block below appends `exit 0`, so on every boot after the first an appended correction sits
# past it and never runs.
SELKIES_CONFIG_RUN="/etc/s6-overlay/s6-rc.d/init-selkies-config/run"
if [ -f "$SELKIES_CONFIG_RUN" ]; then
    # Drop the trailing correction earlier versions appended, now applied at the source.
    sed -i '/^# XDG_RUNTIME_DIR override reconciled$/,+1d' "$SELKIES_CONFIG_RUN"
    sed -i "s|^.*> */run/s6/container_environment/XDG_RUNTIME_DIR *\$|printf '%s' '$XDG_RUNTIME_DIR' > /run/s6/container_environment/XDG_RUNTIME_DIR|" "$SELKIES_CONFIG_RUN"
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
