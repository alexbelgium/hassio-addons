#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

if bashio::config.has_value 'additional_apps'; then
    packages="$(bashio::config 'additional_apps')"
    apt-get update -o Acquire::http::Timeout=10 -o Acquire::https::Timeout=10
    for package in ${packages//,/ }; do
        bashio::log.info "Installing apt package: $package"
        apt-get install -y --no-install-recommends "$package"
    done
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

if bashio::config.has_value 'additional_pip'; then
    packages="$(bashio::config 'additional_pip')"
    for package in ${packages//,/ }; do
        bashio::log.info "Installing pip package: $package"
        pip3 install --break-system-packages "$package"
    done
fi

if bashio::config.has_value 'TZ'; then
    timezone="$(bashio::config 'TZ')"
    if [ ! -e "/usr/share/zoneinfo/$timezone" ]; then
        bashio::log.fatal "Invalid timezone: $timezone"
        exit 1
    fi
    ln -snf "/usr/share/zoneinfo/$timezone" /etc/localtime
    printf '%s\n' "$timezone" > /etc/timezone
fi
