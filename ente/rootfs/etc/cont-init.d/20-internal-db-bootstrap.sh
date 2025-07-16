#!/usr/bin/with-contenv bashio
set -euo pipefail

if bashio::config.true 'USE_EXTERNAL_DB'; then
	bashio::log.info "External DB in use; skipping internal Postgres bootstrap."
	exit 0
fi

bashio::log.info "Bootstrapping internal Postgres cluster…"

DB_USER="$(bashio::config 'DB_USERNAME')"
DB_PASS="$(bashio::config 'DB_PASSWORD')"
DB_NAME="$(bashio::config 'DB_DATABASE_NAME')"

# Wait for postgres service (localhost)
until pg_isready -q -h localhost -p 5432 -U postgres; do
	bashio::log.info "Waiting for Postgres to accept connections…"
	sleep 1

bashio::log.info "Creating role + database if needed…"
su - postgres -c psql <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}') THEN
      CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
   END IF;
END
\$\$;
SQL

bashio::log.info "Internal Postgres ready."

done
