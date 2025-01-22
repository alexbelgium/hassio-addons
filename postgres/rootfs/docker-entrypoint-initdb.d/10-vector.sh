#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

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
