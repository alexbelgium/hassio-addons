#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -d /data/database ]; then
    bashio::log.warning "Database migrated to /config"
    mv /data/database /config
fi

if [ -f /homeassistant/addons_config/postgres/config.yaml ]; then
    bashio::log.warning "Config migrated to /config"
    mv /homeassistant/addons_config/postgres/*  /config/
    rm -r /homeassistant/addons_config/postgres
fi
