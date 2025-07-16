#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

############################################
# Persistent dirs
############################################
mkdir -p /config/ente/custom-logs
mkdir -p /config/data
mkdir -p /config/minio-data
mkdir -p /config/postgres-data
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
# Paths to binaries
############################################
INITDB="$(command -v initdb || echo /usr/bin/initdb)"
POSTGRES_BIN="$(command -v postgres || echo /usr/bin/postgres)"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"
MUSEUM_BIN="/usr/bin/museum"
WEB_BIN="/usr/bin/ente-web"

# unify PGDATA
PGDATA="/config/postgres-data"

############################################
# Functions
############################################

start_postgres() {
    if $USE_EXTERNAL_DB; then
        bashio::log.info "External DB enabled; skipping internal Postgres start."
        return 0
    fi

    # runtime socket dir
    mkdir -p /run/postgresql
    chown postgres:postgres /run/postgresql
    chmod 775 /run/postgresql

    # data dir
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
    local host port user
    if $USE_EXTERNAL_DB; then
        host="$DB_HOST_EXT"
        port="$DB_PORT_EXT"
        user="$DB_USER"
        bashio::log.info "Waiting for EXTERNAL Postgres at ${host}:${port}..."
    else
        host="$DB_HOST_INTERNAL"
        port="$DB_PORT_INTERNAL"
        user="postgres"  # cluster superuser for initial readiness
        bashio::log.info "Waiting for internal Postgres..."
    fi
    until pg_isready -q -h "$host" -p "$port" -U "$user"; do
        sleep 1
    done
    bashio::log.info "Postgres reachable."
}

bootstrap_internal_db() {
    if $USE_EXTERNAL_DB; then
        return 0
    fi

    # Escape single quotes in password for SQL
    local esc_pass="${DB_PASS//\'/\'\'}"

    bashio::log.info "Ensuring role ${DB_USER} exists..."
    if ! su - postgres -c "psql -Atqc \"SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'\" postgres" | grep -q 1; then
        su - postgres -c "psql -v ON_ERROR_STOP=1 -c \"CREATE ROLE \\\"${DB_USER}\\\" LOGIN PASSWORD '${esc_pass}'\" postgres"
    else
        # update password in case it changed
        su - postgres -c "psql -v ON_ERROR_STOP=1 -c \"ALTER ROLE \\\"${DB_USER}\\\" PASSWORD '${esc_pass}'\" postgres"
    fi

    bashio::log.info "Ensuring database ${DB_NAME} exists (owner ${DB_USER})..."
    if ! su - postgres -c "psql -Atqc \"SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'\" postgres" | grep -q 1; then
        su - postgres -c "createdb -O \"${DB_USER}\" \"${DB_NAME}\""
    else
        # make sure owner is correct
        su - postgres -c "psql -v ON_ERROR_STOP=1 -c \"ALTER DATABASE \\\"${DB_NAME}\\\" OWNER TO \\\"${DB_USER}\\\"\" postgres"
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
    bashio::log.info "Starting Ente web (:3000)..."
    "$WEB_BIN" &
    WEB_PID=$!
}

start_museum_foreground() {
    local cfg=/config/museum.yaml
    if ! bashio::fs.file_exists "$cfg"; then
        bashio::log.error "$cfg missing; cannot start museum."
        return 1
    fi

    # If internal DB, verify DB_USER can connect (role creation just happened)
    if ! $USE_EXTERNAL_DB; then
        bashio::log.info "Verifying internal DB user '${DB_USER}' connectivity..."
        until pg_isready -q -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U "$DB_USER"; do
            sleep 1
        done
    fi

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

# foreground: keeps container alive
start_museum_foreground
