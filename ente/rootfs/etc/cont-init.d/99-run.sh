#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

mkdir -p /config/ente/custom-logs
mkdir -p /config/data
mkdir -p /config/minio-data
mkdir -p /config/postgres-data
mkdir -p /config/scripts/compose

################
# Run services #
################

bashio::log.info "Starting services"
for dir in /etc/services.d/*; do
	# Check if the directory contains a 'run' file
	if [ -f "$dir/run" ]; then
		# Execute the 'run' file
		bashio::log.info "Starting service $dir"
		/."$dir/run"
	else
		bashio::log.fatal "No run file found in $dir"
	fi
done

#########################
# Internal db bootstrap #
#########################

#Default values for internal
DB_NAME="ente_db"
DB_USER="pguser"
DB_PASS="ente"

if bashio::config.true 'USE_EXTERNAL_DB'; then
	bashio::log.info "External DB in use; skipping internal Postgres bootstrap."
	DB_USER="$(bashio::config 'DB_USERNAME')"
	DB_PASS="$(bashio::config 'DB_PASSWORD')"
	DB_NAME="$(bashio::config 'DB_DATABASE_NAME')"
fi

bashio::log.info "Bootstrapping Postgres cluster…"

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

#################
# Minio startup #
#################

MINIO_USER="$(bashio::config 'MINIO_ROOT_USER')"
MINIO_PASS="$(bashio::config 'MINIO_ROOT_PASSWORD')"
S3_BUCKET="$(bashio::config 'S3_BUCKET')"

bashio::log.info "Waiting for MinIO API…"
until /usr/local/bin/mc alias set h0 http://localhost:3200 "${MINIO_USER}" "${MINIO_PASS}" 2>/dev/null; do
	sleep 1
done

bashio::log.info "Ensuring bucket ${S3_BUCKET} exists…"
/usr/local/bin/mc mb -p "h0/${S3_BUCKET}" || true
bashio::log.info "MinIO bucket ready."

sleep infinity
