#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Comicarr keeps its config.ini, sqlite database, logs and cover cache in the
# datadir it is started with. /config is the addon_config mount, so using
# /config/comicarr reproduces the layout of the upstream compose file's
# "./config:/config" volume : an existing installation can be copied in as is.

CONFIG_LOCATION="/config/comicarr"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION"

# Numbered 20- on purpose : it must sort after 00-global_var.sh, which is what
# exports PUID/PGID from the addon options. The upstream image sets neither, so
# the fallbacks only apply when the module is absent.
# Not recursive : the cover cache under $CONFIG_LOCATION grows to thousands of
# files, and walking it on every boot would delay startup for no gain. This is
# what the upstream entrypoint does too.
chown "${PUID:-0}:${PGID:-0}" /config "$CONFIG_LOCATION"

# The upstream entrypoint installs the timezone when it runs, and the default
# path in services.d/comicarr/run bypasses it, so do it here for both paths.
if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi
