#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Use new config file
CONFIG_HOME="$(bashio::config "CONFIG_LOCATION")"
CONFIG_HOME="$(dirname "$CONFIG_HOME")"
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
    bashio::log.warning "The config.env file found in $CONFIG_HOME will be used. Please customize according to https://hub.docker.com/_/postgres and restart the add-on"
fi

# Define home
# Creating config location
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 777 "$PGDATA"

# Permissions
chmod -R 777 "$CONFIG_HOME"

#####################
# Prepare vector.rs #
#####################

# Set variables for vector.rs
DB_PORT=5432
DB_HOSTNAME=localhost
DB_USERNAME=postgres
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
export DB_PORT
export DB_HOSTNAME
export DB_USERNAME
export DB_PASSWORD
echo "DROP EXTENSION IF EXISTS vectors;
    CREATE EXTENSION vectors;
\q"> setup_postgres.sql

##############
# Launch App #
##############

# Go to folder
cd /config || true

echo " "
bashio::log.info "Starting the app"
echo " "

# Add docker-entrypoint command
if [ "$(bashio::info.arch)" != "armv7" ]; then
    sed -i "/exec \"\$@\"/i psql \"postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT\" < setup_postgres.sql || true" docker-entrypoint.sh
    docker-entrypoint.sh postgres -c shared_preload_libraries=vectors.so
else
    bashio::log.warning "Your architecture is armv7, vector.rs is disabled as not supported"
    docker-entrypoint.sh postgres
fi
