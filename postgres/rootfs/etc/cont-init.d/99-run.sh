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

####################
# Enable vector.rs #
####################

bashio::log.info "Waiting for port 5432 to open..."

# Wait for transmission to become available
( bashio::net.wait_for 5432 localhost 900

bashio::log.info "Enabling vector.rs"

# Set variables for vector.rs
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
if bashio::config.has_value "POSTGRES_USER"; then DB_USERNAME="$(bashio::config "POSTGRES_USER")"; else DB_USERNAME=postgres; fi

export DB_PORT
export DB_HOSTNAME
export DB_USERNAME
export DB_PASSWORD
echo "DROP EXTENSION IF EXISTS vectors;
    CREATE EXTENSION vectors;
\q" > /setup_postgres.sql

# Enable vectors
psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" < /setup_postgres.sql >/dev/null || true
rm /setup_postgres.sql || true
) & true
