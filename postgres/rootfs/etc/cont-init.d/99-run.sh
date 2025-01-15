#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIG_HOME="/config"
mkdir -p "$CONFIG_HOME"
if [ ! -f "$CONFIG_HOME/postgresql.conf" ]; then
    if [ -f /usr/local/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/local/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    elif [ -f /usr/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/share/postgresql/postgresql.conf.sample "$CONFIG_HOME/postgresql.conf"
    else
        bashio::exit.nok "Config file not found, please ask maintainer"
        exit 1
    fi
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
else
    bashio::log.warning "Using existing config.env file in $CONFIG_HOME."
fi

# Setup data directory
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# Set permissions
chmod -R 755 "$CONFIG_HOME"

##############
# Launch App #
##############

cd /config || true

bashio::log.info "Starting the app"

# Start background tasks
if [ "$(bashio::info.arch)" != "armv7" ]; then
#    /./docker-entrypoint-initdb.d/10-vector.sh & true
    docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so -c search_path="public, vectors" & true
else
    bashio::log.warning "ARMv7 detected: Starting without vectors.so"
    docker-entrypoint.sh postgres & true
fi
