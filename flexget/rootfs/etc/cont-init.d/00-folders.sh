#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

slug=flexget

if [ "$(bashio::config 'WebuiPass')" = "homeassistant123" ]; then
    bashio::log.warning "SECURITY RISK: the FlexGet web UI password is still the default (homeassistant123)."
    bashio::log.warning "Anyone who can reach port 5050 can log in and change tasks, which can run commands."
    bashio::log.warning "Set a new WebuiPass in the add-on options."
fi

if [ -d /config/$slug ]; then
    echo "Moving to new location /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
    chmod 755 /config/addons_config/$slug
    mv /config/$slug/* /config/addons_config/$slug/
    rm -r /config/$slug
fi

if [ ! -d /config/addons_config/$slug ]; then
    echo "Creating /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
    chmod 755 /config/addons_config/$slug
fi
