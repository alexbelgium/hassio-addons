#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Komga stores its database, logs and search index in KOMGA_CONFIGDIR, which the
# upstream image sets to /config -- that is the addon_config mount

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
# Defaults matter : this script sorts before 00-global_var.sh, which is what
# exports PUID/PGID from the addon options, and the upstream image sets neither
chown -R "${PUID:-0}:${PGID:-0}" "$CONFIG_LOCATION"
