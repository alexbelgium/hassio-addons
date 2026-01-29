#!/usr/bin/with-contenv bashio
# shellcheck shell=bash disable=SC2016
set -e

# ======================================================================
# Banner
# ======================================================================

if ! bashio::supervisor.ping 2>/dev/null; then
    bashio::log.blue '-----------------------------------------------------------'
    bashio::log.blue "Starting addon in standalone mode (no Supervisor)"
    bashio::log.blue "Version : ${BUILD_VERSION:-1.0}"
    bashio::log.blue "Config source: ENV + /data/options.json"
    bashio::log.blue '-----------------------------------------------------------'
else
    bashio::log.blue '-----------------------------------------------------------'
    bashio::log.blue " Add-on: $(bashio::addon.name)"
    bashio::log.blue " $(bashio::addon.description)"
    bashio::log.blue '-----------------------------------------------------------'

    bashio::log.blue " Add-on version: $(bashio::addon.version)"
    if bashio::var.true "$(bashio::addon.update_available)"; then
        bashio::log.magenta " There is an update available!"
        bashio::log.magenta " Latest version: $(bashio::addon.version_latest)"
    else
        bashio::log.green " You are running the latest version."
    fi

    bashio::log.blue " System: $(bashio::info.operating_system)"
    bashio::log.blue " Architecture: $(bashio::info.arch) / $(bashio::info.machine)"
    bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
    bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"
fi

bashio::log.blue '-----------------------------------------------------------'
bashio::log.green ' Provided by: https://github.com/alexbelgium/hassio-addons '
bashio::log.blue '-----------------------------------------------------------'

# ======================================================================
# UID/GID logic stays unchanged
# ======================================================================

if bashio::config.has_value "PUID" && bashio::config.has_value "PGID" && id abc &>/dev/null; then
    PUID="$(bashio::config "PUID")"
    PGID="$(bashio::config "PGID")"
    usermod -o -u "$PUID" abc
    groupmod -o -g "$PGID" abc
fi

[ -f ~/.bashrc ] && : > ~/.bashrc
