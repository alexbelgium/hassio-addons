#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Use new config file
CONFIG_HOME="/config"
mkdir -p "$CONFIG_HOME"
if [ ! -f "$CONFIG_HOME"/postgresql.conf ]; then
    # Copy default config.env
    if [ -f /usr/local/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/local/share/postgresql/postgresql.conf.sample "$CONFIG_HOME"/postgresql.conf
    elif [ -f /usr/share/postgresql/postgresql.conf.sample ]; then
        cp /usr/share/postgresql/postgresql.conf.sample "$CONFIG_HOME"/postgresql.conf
    else
        bashio::exit.nok "Config file not found, please ask maintainer"
    fi
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
else
    bashio::log.warning "The config.env file found in $CONFIG_HOME will be used (mapped to /addon_configs/xxx-postgres when accessing from Filebrowser). Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
fi

# Define home
# Creating config location
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 777 "$PGDATA"

# Permissions
chmod -R 777 "$CONFIG_HOME"

##############
# Launch App #
##############

# Function to handle SIGTERM
function shutdown_postgres {
    echo "Received SIGTERM, shutting down PostgreSQL..."
    pg_ctl -D "$PGDATA" -m fast stop
    exit 0
}
trap 'shutdown_postgres' SIGTERM

# Go to folder
cd /config || true

echo " "
bashio::log.info "Starting the app"
echo " "

# Add docker-entrypoint command
if [ "$(bashio::info.arch)" != "armv7" ]; then
    # Exec vector modification
    /./docker-entrypoint-initdb.d/10-vector.sh & \
    docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so &
else
    bashio::log.warning "Your architecture is armv7, pgvecto.rs is disabled as not supported"
    docker-entrypoint.sh postgres &
fi

# Wait for all background processes to finish
wait
