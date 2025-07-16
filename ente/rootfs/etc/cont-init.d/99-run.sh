#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

############################################
# Persistent dirs
############################################
mkdir -p /config/ente/custom-logs
mkdir -p /config/data
mkdir -p /config/minio-data
mkdir -p /config/postgres
mkdir -p /config/scripts/compose

############################################
# Config / options
############################################
USE_EXTERNAL_DB=false
if bashio::config.true 'USE_EXTERNAL_DB'; then
	USE_EXTERNAL_DB=true
fi

DB_NAME="$(bashio::config 'DB_DATABASE_NAME')"
DB_USER="$(bashio::config 'DB_USERNAME')"
DB_PASS="$(bashio::config 'DB_PASSWORD')"
DB_HOST_INTERNAL=127.0.0.1
DB_PORT_INTERNAL=5432

DB_HOST_EXT="$(bashio::config 'DB_HOSTNAME')"
DB_PORT_EXT="$(bashio::config 'DB_PORT')"

MINIO_USER="$(bashio::config 'MINIO_ROOT_USER')"
MINIO_PASS="$(bashio::config 'MINIO_ROOT_PASSWORD')"
S3_BUCKET="$(bashio::config 'S3_BUCKET')"

DISABLE_WEB_UI=false
if bashio::config.true 'DISABLE_WEB_UI'; then
	DISABLE_WEB_UI=true
fi

############################################
# Paths to binaries (discover; DO NOT mv)
############################################
INITDB="$(command -v initdb || echo /usr/bin/initdb)"
POSTGRES_BIN="$(command -v postgres || echo /usr/bin/postgres)"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"

MUSEUM_BIN="$(command -v museum || true)"
[ -z "$MUSEUM_BIN" ] && [ -x /app/museum ] && MUSEUM_BIN=/app/museum
[ -z "$MUSEUM_BIN" ] && [ -x /museum ] && MUSEUM_BIN=/museum
[ -z "$MUSEUM_BIN" ] && MUSEUM_BIN=museum # last resort: PATH

WEB_BIN="$(command -v ente-web || true)"
[ -z "$WEB_BIN" ] && [ -x /app/ente-web ] && WEB_BIN=/app/ente-web
[ -z "$WEB_BIN" ] && [ -x /ente-web ] && WEB_BIN=/ente-web

PGDATA="/config/postgres"

############################################
# Functions
############################################

start_postgres() {
	if $USE_EXTERNAL_DB; then
		bashio::log.info "External DB enabled; skipping internal Postgres start."
		return 0
	fi

	mkdir -p /run/postgresql
	chown postgres:postgres /run/postgresql
	chmod 775 /run/postgresql

	mkdir -p "$PGDATA"
	chown -R postgres:postgres "$PGDATA"
	chmod 0700 "$PGDATA"

	if [[ ! -s "$PGDATA/PG_VERSION" ]]; then
		bashio::log.info "Initializing Postgres data directory..."
		su - postgres -c "$INITDB -D $PGDATA"
	fi

	bashio::log.info "Starting Postgres (127.0.0.1:5432)..."
	su - postgres -c "$POSTGRES_BIN -D $PGDATA -c listen_addresses='127.0.0.1'" &
	PG_PID=$!
}

wait_postgres_ready() {
	local host port
	if $USE_EXTERNAL_DB; then
		host="$DB_HOST_EXT"
		port="$DB_PORT_EXT"
		bashio::log.info "Waiting for EXTERNAL Postgres at ${host}:${port}..."
	else
		host="$DB_HOST_INTERNAL"
		port="$DB_PORT_INTERNAL"
		bashio::log.info "Waiting for internal Postgres..."
	fi
	until pg_isready -q -h "$host" -p "$port"; do
		sleep 1
	done
	bashio::log.info "Postgres reachable."
}

bootstrap_internal_db() {
	if $USE_EXTERNAL_DB; then
		return 0
	fi

	bashio::log.info "Creating role/database if needed..."

	local esc_pass="${DB_PASS//\'/\'\'}"

	# role
	if ! psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -tAc \
		"SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" | grep -q 1; then
		psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres \
			-c "CREATE ROLE \"${DB_USER}\" LOGIN PASSWORD '${esc_pass}';"
	else
		psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres \
			-c "ALTER ROLE \"${DB_USER}\" PASSWORD '${esc_pass}';"
	fi

	# db
	if ! psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -tAc \
		"SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
		psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres \
			-c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";"
	else
		psql -v ON_ERROR_STOP=1 -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres \
			-c "ALTER DATABASE \"${DB_NAME}\" OWNER TO \"${DB_USER}\";"
	fi

	bashio::log.info "Internal Postgres ready."
}

start_minio() {
	bashio::log.info "Starting MinIO (:3200)..."
	mkdir -p /config/minio-data
	"$MINIO_BIN" server /config/minio-data --address ":3200" &
	MINIO_PID=$!
}

wait_minio_ready_and_bucket() {
	bashio::log.info "Waiting for MinIO API..."
	until "$MC_BIN" alias set h0 http://127.0.0.1:3200 "$MINIO_USER" "$MINIO_PASS" 2>/dev/null; do
		sleep 1
	done
	bashio::log.info "Ensuring bucket ${S3_BUCKET}..."
	"$MC_BIN" mb -p "h0/${S3_BUCKET}" || true
	bashio::log.info "MinIO bucket ready."
}

start_web() {
    if $DISABLE_WEB_UI; then
        bashio::log.info "Web UI disabled."
        return 0
    fi

    # Prepare static assets with actual origins (does safe sed replacements).
    ENTE_API_ORIGIN="${ENTE_API_ORIGIN:-http://[HOST]:[PORT:8080]}"
    ENTE_ALBUMS_ORIGIN="${ENTE_ALBUMS_ORIGIN:-${ENTE_API_ORIGIN}}"
    export ENTE_API_ORIGIN ENTE_ALBUMS_ORIGIN
    /usr/local/bin/ente-web-prepare || bashio::log.warning "Web env substitution step returned non‑zero; continuing."

    # nginx expects runtime dirs
    mkdir -p /run/nginx
    # log dir
    mkdir -p /var/log/nginx

    bashio::log.info "Starting Ente web (nginx, ports 3000‑3004)..."
    nginx -c /etc/ente-web/nginx.conf -g 'daemon off;' &
    WEB_PID=$!
}

start_museum_foreground() {
	local cfg=/config/museum.yaml
	if ! bashio::fs.file_exists "$cfg"; then
		bashio::log.error "$cfg missing; cannot start museum."
		return 1
	fi
	if [ ! -x "$MUSEUM_BIN" ] && ! command -v "$MUSEUM_BIN" >/dev/null 2>&1; then
		bashio::log.error "Museum binary not found; cannot launch Ente API."
		return 1
	fi

	# Export ENTE_* overrides to guarantee correct credentials parsing.
	# (Museum merges env vars over YAML.)
	# Ref: environment override mechanism in museum docs. :contentReference[oaicite:2]{index=2}
	if $USE_EXTERNAL_DB; then
		export ENTE_DB_HOST="$DB_HOST_EXT"
		export ENTE_DB_PORT="$DB_PORT_EXT"
	else
		export ENTE_DB_HOST="$DB_HOST_INTERNAL"
		export ENTE_DB_PORT="$DB_PORT_INTERNAL"
	fi
	export ENTE_DB_USER="$DB_USER"
	export ENTE_DB_PASSWORD="$DB_PASS"
	export ENTE_DB_NAME="$DB_NAME"
	export ENTE_DB_SSLMODE=disable

	bashio::log.info "Starting museum (foreground)..."
	exec "$MUSEUM_BIN" --config "$cfg"
}

############################################
# Main orchestration
############################################
bashio::log.info "=== Ente startup sequence ==="

start_postgres
wait_postgres_ready
bootstrap_internal_db

start_minio
wait_minio_ready_and_bucket

start_web

start_museum_foreground
