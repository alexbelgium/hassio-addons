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
    source /usr/local/lib/bashio-standalone.sh
    cp -rf /usr/local/lib/bashio-standalone.sh /usr/bin/bashio
    grep -rlZ "^#!.*bashio" /etc |
    while IFS= read -r -d '' f; do
        grep -qF "source /usr/local/lib/bashio-standalone.sh" "$f" && continue
        sed -i '1a source /usr/local/lib/bashio-standalone.sh' "$f"
    done
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

# Adapt user abc
if command -v id &>/dev/null && id abc &>/dev/null; then
    if bashio::config.has_value "PUID" && bashio::config.has_value "PGID"; then
        PUID="$(bashio::config "PUID")"
        PGID="$(bashio::config "PGID")"
        usermod -o -u "${PUID:-0}" abc
        groupmod -o -g "${PGID:-0}" abc
    fi
fi
