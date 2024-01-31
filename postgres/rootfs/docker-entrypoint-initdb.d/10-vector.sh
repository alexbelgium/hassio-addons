#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

echo "Setting 

#####################
# Prepare vector.rs #
#####################

# Set variables for vector.rs
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_USERNAME=postgres
if bashio::config.has_value "POSTGRES_USER"; then POSTGRES_USER="$(bashio::config "POSTGRES_USER")"; else POSTGRES_USER=postgres; fi

export DB_PORT
export DB_HOSTNAME
export DB_USERNAME
export DB_PASSWORD
echo "DROP EXTENSION IF EXISTS vectors;
    CREATE EXTENSION vectors;
\q"> setup_postgres.sql

# Enable vectors
psql \"postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" < setup_postgres.sql || true
