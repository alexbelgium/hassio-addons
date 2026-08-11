#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Komga stores its database, logs and search index in KOMGA_CONFIGDIR, which the
# upstream image sets to /config -- that is the addon_config mount

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
chown -R "$PUID:$PGID" "$CONFIG_LOCATION"
