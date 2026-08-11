#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Komga stores its database, logs and search index in KOMGA_CONFIGDIR, which the
# upstream image sets to /config -- that is the addon_config mount

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"
# Numbered 20- on purpose : it must sort after 00-global_var.sh, which is what
# exports PUID/PGID from the addon options. The upstream image sets neither, so
# the fallbacks only apply when the module is absent.
chown -R "${PUID:-0}:${PGID:-0}" "$CONFIG_LOCATION"
