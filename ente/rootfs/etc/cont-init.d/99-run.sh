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
# Paths to binaries
############################################
INITDB="$(command -v initdb || echo /usr/bin/initdb)"
POSTGRES_BIN="$(command -v postgres || echo /usr/bin/postgres)"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"

# runtime binary resolver
resolve_bin() {
    local name="$1"; shift
    local cand
    for cand in "$@"; do
        [ -x "$cand" ] && { echo "$cand"; return 0; }
    done
    cand="$(command -v "$name" 2>/dev/null || true)"
    [ -n "$cand" ] && { echo "$cand"; return 0; }
    echo ""
    return 1
}

MUSEUM_BIN="$(resolve_bin museum /usr/bin/museum /usr/local/bin/museum /app/museum /museum)"
WEB_BIN="$(resolve_bin ente-web /usr/bin/ente-web /usr/local/bin/ente-web /app/ente-web /ente-web)"

if [ -z "$MUSEUM_BIN" ]; then
    bashio::log.error "museum binary not found; cannot start Ente API."
    exit 1
fi

if ! $DISABLE_WEB_UI && [ -z "$WEB_BIN" ]; then
    bashio::log.warning "Ente web binary not found; disabling web UI."
    DISABLE_WEB_UI=true
fi

PGDATA="/config/postgres"

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
        user="postgres"  # superuser for first readiness check
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

    bashio::log.info "Ensuring role ${DB_USER} exists..."
    if ! psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -tAc \
        "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" \
        | grep -q 1; then
        # password quoting: single quotes doubled
        esc_pass="${DB_PASS//\'/\'\'}"
        psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -c \
            "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${esc_pass}'" || true
    else
        psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -c \
            "ALTER ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS//\'/\'\'}'" >/dev/null 2>&1 || true
    fi
    bashio::log.info "Ensuring database ${DB_NAME} exists (owner ${DB_USER})..."
    if ! psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -tAc \
        "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" \
        | grep -q 1; then
        # CREATE DATABASE must be top-level (not in DO/transaction). :contentReference[oaicite:2]{index=2}
        psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U postgres -c \
            "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}"
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
    bashio::log.info "Starting Ente web (:3000) using $WEB_BIN ..."
    "$WEB_BIN" &
    WEB_PID=$!
}

start_museum_foreground() {
    local cfg=/config/museum.yaml
    if ! bashio::fs.file_exists "$cfg"; then
        bashio::log.error "$cfg missing; cannot start museum."
        return 1
    fi

    # For internal DB: verify reached DB_NAME
    if ! $USE_EXTERNAL_DB; then
        bashio::log.info "Verifying internal DB '${DB_NAME}' as '${DB_USER}'..."
        until PGPASSWORD="$DB_PASS" psql -h "$DB_HOST_INTERNAL" -p "$DB_PORT_INTERNAL" -U "$DB_USER" -d "$DB_NAME" -c 'SELECT 1;' >/dev/null 2>&1; do
            sleep 1
        done
    else
        bashio::log.info "Using external DB; skipping final local verification."
    fi

    bashio::log.info "Starting museum (foreground) using $MUSEUM_BIN ..."
    # museum loads /config/museum.yaml to override defaults. :contentReference[oaicite:3]{index=3}
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

# Last: foreground museum keeps container alive
start_museum_foreground
