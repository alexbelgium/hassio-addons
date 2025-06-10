#!/usr/bin/with-contenv bashio
# shellcheck shell=bash disable=SC2016
set -e
# ==============================================================================
# Displays a simple add-on banner on startup
# ==============================================================================

if ! bashio::supervisor.ping 2> /dev/null; then
    # Degraded mode if no homeassistant
    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue "Starting addon without HA support"
    bashio::log.blue "Version : ${BUILD_VERSION:-1.0}"
    bashio::log.blue "Please use Docker Compose for env variables"
    bashio::log.blue \
        '-----------------------------------------------------------'
    # Use environment variables instead of addon options
    echo "... convert scripts to use environment variables instead of addon options"
    while IFS= read -r scripts; do
        sed -i -e 's/bashio::config.has_value[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"']/[ ! -z "${\1:-}" ]/g' \
            -e 's/bashio::config.true[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"']/[ ! -z "${\1:-}" ] \&\& [ "${\1:-}" = "true" ]/g' \
            -e 's/\$(bashio::config[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'])/${\1:-}/g' \
            -e 's/\$(bashio::addon.port[[:space:]]*["'"'"']\([0-9]*\)["'"'"'])/${\1:-}/g' \
            -e 's/bashio::config.require.ssl/true/g' \
            -e 's/\$(bashio::addon.ingress_port)/""/g' \
            -e 's/\$(bashio::addon.ingress_entry)/""/g' \
            -e 's/\$(bashio::addon.ip_address)/""/g' "$scripts"
  done   < <(grep -srl "bashio" /etc/cont-init.d /custom-services.d)
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
if bashio::config.has_value "PUID" && bashio::config.has_value "PGID" && id abc &> /dev/null; then
    bashio::log.green ' Defining permissions for main user : '
    PUID="$(bashio::config "PUID")"
    PGID="$(bashio::config "PGID")"
    usermod -o -u "$PUID" abc
    groupmod -o -g "$PGID" abc
    bashio::log.blue "User UID: $(id -u abc)"
    bashio::log.blue "User GID: $(id -g abc)"

    bashio::log.blue \
        '-----------------------------------------------------------'
fi

# Clean bashrc file safely
if [ -f ~/.bashrc ]; then : > ~/.bashrc; fi
