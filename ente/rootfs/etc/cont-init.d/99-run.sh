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

bashio::log.info "Postgres-init: waiting for local Postgres..."
until pg_isready -q -h 127.0.0.1 -p 5432 -U postgres; do
	sleep 1
done

bashio::log.info "Postgres-init: creating role/database if missing..."
# psql search_path safe quoting using dollar-quoted strings for password
psql -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 5432 -U postgres <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      EXECUTE 'CREATE ROLE ${DB_USER} LOGIN PASSWORD ''' || replace('${DB_PASS}','''','''''') || '''';
   END IF;
   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}') THEN
      EXECUTE 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}';
   END IF;
END
\$\$;
SQL

bashio::log.info "Postgres-init: done."

#################
# Minio startup #
#################

#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

MINIO_USER="$(bashio::config 'MINIO_ROOT_USER')"
MINIO_PASS="$(bashio::config 'MINIO_ROOT_PASSWORD')"
S3_BUCKET="$(bashio::config 'S3_BUCKET')"

bashio::log.info "MinIO-init: waiting for API..."
until /usr/local/bin/mc alias set h0 http://127.0.0.1:3200 "${MINIO_USER}" "${MINIO_PASS}" 2>/dev/null; do
    sleep 1
done

bashio::log.info "MinIO-init: ensuring bucket ${S3_BUCKET}..."
/usr/local/bin/mc mb -p "h0/${S3_BUCKET}" || true

bashio::log.info "MinIO-init: done."

sleep infinity
