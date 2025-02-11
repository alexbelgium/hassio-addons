#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
# ==============================================================================
# Displays a simple add-on banner on startup
# ==============================================================================

if ! bashio::supervisor.ping 2>/dev/null; then
    # Degraded mode if no homeassistant
    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue " Starting addon without HA support"
    bashio::log.blue \
        '-----------------------------------------------------------'
    # Fake options.json
    mkdir -p /data
    touch /data/option.json
    exit 0
fi

bashio::log.blue \
    '-----------------------------------------------------------'
bashio::log.blue " Add-on: $(bashio::addon.name)"
bashio::log.blue " $(bashio::addon.description)"
bashio::log.blue \
    '-----------------------------------------------------------'

bashio::log.blue " Add-on version: $(bashio::addon.version)"
if bashio::var.true "$(bashio::addon.update_available)"; then
    bashio::log.magenta ' There is an update available for this add-on!'
    bashio::log.magenta \
        " Latest add-on version: $(bashio::addon.version_latest)"
    bashio::log.magenta ' Please consider upgrading as soon as possible.'
else
    bashio::log.green ' You are running the latest version of this add-on.'
fi

bashio::log.blue " System: $(bashio::info.operating_system)"
bashio::log.blue " Architecture: $(bashio::info.arch) / $(bashio::info.machine)"
bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

bashio::log.blue \
    '-----------------------------------------------------------'
bashio::log.blue \
    ' Please, share the above information when looking for help'
bashio::log.blue \
    ' or support in, e.g., GitHub, forums'
bashio::log.blue \
    '-----------------------------------------------------------'
bashio::log.green \
    ' Provided by: https://github.com/alexbelgium/hassio-addons '
bashio::log.blue \
    '-----------------------------------------------------------'

# ==============================================================================
# Global actions for all addons
# ==============================================================================
if bashio::config.has_value "PUID" && bashio::config.has_value "PGID"; then
    bashio::log.green ' Defining permissions for main user : '
    PUID="$(bashio::config "PUID")"
    PGID="$(bashio::config "PGID")"
    bashio::log.blue "User UID: $PUID"
    bashio::log.blue "User GID: $PGID"
    
    # Only modify user/group if they exist
    if id abc &>/dev/null; then
        usermod -o -u "$PUID" abc &>/dev/null
    fi
    if getent group abc &>/dev/null; then
        groupmod -o -g "$PGID" abc &>/dev/null
    fi
    
    bashio::log.blue \
        '-----------------------------------------------------------'
fi

# Clean bashrc file safely
if [ -f ~/.bashrc ]; then > ~/.bashrc; fi
