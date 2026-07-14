#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"
LOCATION="$(bashio::config 'data_location')"

if [ -z "$LOCATION" ] || [ "$LOCATION" = "null" ]; then
    LOCATION="/data/data"
fi

case "$LOCATION" in
    /data/* | /share/* | /media/* | /config/* | /mnt/*)
        ;;
    *)
        bashio::log.fatal "data_location must be below /data, /share, /media, /config, or /mnt"
        exit 1
        ;;
esac

if [ -L "$LOCATION" ]; then
    bashio::log.fatal "data_location must not be a symbolic link"
    exit 1
fi

bashio::log.info "Using persistent home: $LOCATION"
install -d -m 0750 -o "$PUID" -g "$PGID" "$LOCATION"
install -d -m 0750 -o "$PUID" -g "$PGID" "$LOCATION/.codex" "$LOCATION/.headroom"
install -d -m 0755 /tmp/cache /run/s6/container_environment

sed -i "s|^\(abc:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*|\1$LOCATION|" /etc/passwd

for variable in HOME CODEX_HOME HEADROOM_WORKSPACE_DIR XDG_CACHE_HOME; do
    case "$variable" in
        HOME) value="$LOCATION" ;;
        CODEX_HOME) value="$LOCATION/.codex" ;;
        HEADROOM_WORKSPACE_DIR) value="$LOCATION/.headroom" ;;
        XDG_CACHE_HOME) value="/tmp/cache" ;;
    esac
    printf '%s' "$value" > "/run/s6/container_environment/$variable"
done

chown -R "$PUID:$PGID" "$LOCATION/.codex" "$LOCATION/.headroom"
chown "$PUID:$PGID" "$LOCATION"
