#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown "${PUID:-0}:${PGID:-0}" /config "$CONFIG_LOCATION"

# Ensure timezone is applied
if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi
