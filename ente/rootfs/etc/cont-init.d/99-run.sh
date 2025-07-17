#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

############################################
# Paths & constants
############################################
CFG=/config/museum.yaml
PGDATA=/config/postgres

# Internal Postgres always bound here
DB_HOST_INTERNAL=127.0.0.1
DB_PORT_INTERNAL=5432

# Resolve mapped ports from Supervisor (fall back to defaults if missing)
API_PORT="$(bashio::addon.port 8080 || echo 8080)"
S3_PORT="$(bashio::addon.port 3200 || echo 3200)"

# Read MinIO creds from add-on config
MINIO_USER="$(bashio::config 'MINIO_ROOT_USER' || echo minioadmin)"
MINIO_PASS="$(bashio::config 'MINIO_ROOT_PASSWORD' || echo minioadmin)"
MINIO_DATA="$(bashio::config 'PHOTOS_LOCATION' || echo /config/minio-data)"

# Env overrides Museum will merge over YAML
export ENTE_API_ORIGIN="http://homeassistant.local:${API_PORT}"
export ENTE_S3_ARE_LOCAL_BUCKETS="true"
# Primary bucket (b2-eu-cen)
export ENTE_S3_B2_EU_CEN_ENDPOINT="http://127.0.0.1:${S3_PORT}"
export ENTE_S3_B2_EU_CEN_REGION="eu-central-2"
export ENTE_S3_B2_EU_CEN_BUCKET="b2-eu-cen"
export ENTE_S3_B2_EU_CEN_KEY="${MINIO_USER}"
export ENTE_S3_B2_EU_CEN_SECRET="${MINIO_PASS}"
export ENTE_S3_WASABI_EU_CENTRAL_2_V3_ENDPOINT="http://127.0.0.1:${S3_PORT}"
export ENTE_S3_WASABI_EU_CENTRAL_2_V3_REGION="eu-central-2"
export ENTE_S3_WASABI_EU_CENTRAL_2_V3_BUCKET="wasabi-eu-central-2-v3"
export ENTE_S3_WASABI_EU_CENTRAL_2_V3_KEY="${MINIO_USER}"
export ENTE_S3_WASABI_EU_CENTRAL_2_V3_SECRET="${MINIO_PASS}"
export ENTE_S3_SCW_EU_FR_V3_ENDPOINT="http://127.0.0.1:${S3_PORT}"
export ENTE_S3_SCW_EU_FR_V3_REGION="eu-central-2"
export ENTE_S3_SCW_EU_FR_V3_BUCKET="scw-eu-fr-v3"
export ENTE_S3_SCW_EU_FR_V3_KEY="${MINIO_USER}"
export ENTE_S3_SCW_EU_FR_V3_SECRET="${MINIO_PASS}"

############################################
# Read add‑on options
############################################
DB_NAME="$(bashio::config 'DB_DATABASE_NAME' || echo ente_db)"
DB_USER="$(bashio::config 'DB_USERNAME' || echo pguser)"
DB_PASS="$(bashio::config 'DB_PASSWORD' || echo ente)"

# External DB opts (may be blank)
DB_HOST_EXT="$(bashio::config 'DB_HOSTNAME' || echo '127.0.0.1')"
DB_PORT_EXT="$(bashio::config 'DB_PORT' || echo '5432')"


# Which bucket name we’ll auto‑create in MinIO
S3_BUCKET="b2-eu-cen"

USE_EXTERNAL_DB=false
if bashio::config.true 'USE_EXTERNAL_DB'; then
    USE_EXTERNAL_DB=true
    bashio::log.warning "USE_EXTERNAL_DB enabled: will connect to external Postgres."
else
    bashio::log.info "Using internal Postgres."
fi

DISABLE_WEB_UI=false
if bashio::config.true 'DISABLE_WEB_UI'; then
    DISABLE_WEB_UI=true
fi

# Active DB connection target (may be overridden below)
if $USE_EXTERNAL_DB; then
    DB_HOST="$DB_HOST_EXT"
    DB_PORT="$DB_PORT_EXT"
else
    DB_HOST="$DB_HOST_INTERNAL"
    DB_PORT="$DB_PORT_INTERNAL"
fi

############################################
# Ensure persistent dirs
############################################
mkdir -p /config/ente/custom-logs \
         /config/data \
         "$MINIO_DATA" \
         "$PGDATA" \
         /config/scripts/compose

############################################
# Locate binaries
############################################
INITDB="$(command -v initdb || echo /usr/bin/initdb)"
POSTGRES_BIN="$(command -v postgres || echo /usr/bin/postgres)"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"

MUSEUM_BIN="$(command -v museum || true)"
[ -z "$MUSEUM_BIN" ] && [ -x /app/museum ] && MUSEUM_BIN=/app/museum
[ -z "$MUSEUM_BIN" ] && [ -x /museum ] && MUSEUM_BIN=/museum
[ -z "$MUSEUM_BIN" ] && MUSEUM_BIN=museum

WEB_PREP_BIN=/usr/local/bin/ente-web-prepare
WEB_NGINX_CONF=/etc/ente-web/nginx.conf

############################################
# Config generation
############################################
create_config() {
    bashio::log.info "Generating new museum config at $CFG"
    _rand_b64()    { head -c "$1" /dev/urandom | base64 | tr -d '\n'; }
    _rand_b64url() { head -c "$1" /dev/urandom | base64 | tr '+/' '-_' | tr -d '\n'; }

    cat >"$CFG" <<EOF
key:
  encryption: $(_rand_b64 32)
  hash: $(_rand_b64 64)

jwt:
  secret: $(_rand_b64url 32)

db:
  host: ${DB_HOST_INTERNAL}
  port: ${DB_PORT_INTERNAL}
  name: ${DB_NAME}
  user: ${DB_USER}
  password: ${DB_PASS}

s3:
  are_local_buckets: true
  b2-eu-cen:
    key: ${MINIO_USER}
    secret: ${MINIO_PASS}
    endpoint: http://127.0.0.1:${S3_PORT}
    region: eu-central-2
    bucket: b2-eu-cen
  wasabi-eu-central-2-v3:
    key: ${MINIO_USER}
    secret: ${MINIO_PASS}
    endpoint: http://127.0.0.1:${S3_PORT}
    region: eu-central-2
    bucket: wasabi-eu-central-2-v3
  scw-eu-fr-v3:
    key: ${MINIO_USER}
    secret: ${MINIO_PASS}
    endpoint: http://127.0.0.1:${S3_PORT}
    region: eu-central-2
    bucket: scw-eu-fr-v3
EOF
}


############################################
# Postgres
############################################
start_postgres() {
    if $USE_EXTERNAL_DB; then
        bashio::log.info "External DB in use; not starting internal Postgres."
        return 0
    fi

    mkdir -p /run/postgresql
    chown postgres:postgres /run/postgresql
    chmod 775 /run/postgresql

    chown -R postgres:postgres "$PGDATA"
    chmod 0700 "$PGDATA"

    if [[ ! -s "$PGDATA/PG_VERSION" ]]; then
        bashio::log.info "Initializing Postgres data directory..."
        su - postgres -c "$INITDB -D $PGDATA"
    fi

    bashio::log.info "Starting Postgres (${DB_HOST_INTERNAL}:${DB_PORT_INTERNAL})..."
    su - postgres -c "$POSTGRES_BIN -D $PGDATA -c listen_addresses='127.0.0.1'" &
    PG_PID=$!
}

wait_postgres_ready() {
    local host port
    if $USE_EXTERNAL_DB; then
        host="$DB_HOST_EXT"; port="$DB_PORT_EXT"
        bashio::log.info "Waiting for EXTERNAL Postgres at ${host}:${port}..."
    else
        host="$DB_HOST_INTERNAL"; port="$DB_PORT_INTERNAL"
        bashio::log.info "Waiting for internal Postgres..."
    fi
    until pg_isready -q -h "$host" -p "$port"; do sleep 1; done
    bashio::log.info "Postgres reachable."
}

bootstrap_internal_db() {
    if $USE_EXTERNAL_DB; then
        return 0
    fi

    bashio::log.info "Ensuring role & database exist..."

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
}

############################################
# MinIO
############################################
start_minio() {
    bashio::log.info "Starting MinIO (:3200)..."
    mkdir -p "$MINIO_DATA"
    "$MINIO_BIN" server "$MINIO_DATA" --address ":3200" &
    MINIO_PID=$!
}

wait_minio_ready_and_bucket() {
    bashio::log.info "Waiting for MinIO API..."
    until "$MC_BIN" alias set h0 http://127.0.0.1:3200 "$MINIO_USER" "$MINIO_PASS" 2>/dev/null; do
        sleep 1
    done
    bashio::log.info "Ensuring buckets..."
    "$MC_BIN" mb -p "h0/${S3_BUCKET}" || true
    "$MC_BIN" mb -p "h0/wasabi-eu-central-2-v3" || true
    "$MC_BIN" mb -p "h0/scw-eu-fr-v3" || true
    bashio::log.info "MinIO buckets ready."
}

############################################
# Web (static nginx bundle)
############################################
start_web() {
    if $DISABLE_WEB_UI; then
        bashio::log.info "Web UI disabled."
        return 0
    fi

    ENTE_API_ORIGIN="${ENTE_API_ORIGIN:-http://[HOST]:[PORT:8080]}"
    ENTE_ALBUMS_ORIGIN="${ENTE_ALBUMS_ORIGIN:-${ENTE_API_ORIGIN}}"
    export ENTE_API_ORIGIN ENTE_ALBUMS_ORIGIN

    if [ -x "$WEB_PREP_BIN" ]; then
        "$WEB_PREP_BIN" || bashio::log.warning "Web env substitution step failed (non‑fatal)."
    else
        bashio::log.warning "Web prep helper not found ($WEB_PREP_BIN); skipping substitution."
    fi

    mkdir -p /run/nginx /var/log/nginx
    if [ ! -f "$WEB_NGINX_CONF" ]; then
        bashio::log.error "Missing nginx conf at $WEB_NGINX_CONF; cannot start web."
        return 1
    fi

    bashio::log.info "Starting Ente web (nginx, ports 3000‑3004)..."
    nginx -c "$WEB_NGINX_CONF" -g 'daemon off;' &
    WEB_PID=$!
}

############################################
# Museum (API)
############################################
start_museum_foreground() {
    if [ ! -f "$CFG" ]; then
        bashio::log.error "$CFG missing; cannot start museum."
        return 1
    fi
    if [ ! -x "$MUSEUM_BIN" ] && ! command -v "$MUSEUM_BIN" >/dev/null 2>&1; then
        bashio::log.error "Museum binary not found; cannot launch Ente API."
        return 1
    fi

    # Force env overrides (museum merges env > yaml)
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
    exec "$MUSEUM_BIN" --config "$CFG"
}

############################################
# Main orchestration
############################################
bashio::log.info "=== Ente startup sequence ==="

if [ ! -f "$CFG" ]; then
    create_config
else
    bashio::log.info "Using existing $CFG."
fi

start_postgres
wait_postgres_ready
bootstrap_internal_db

start_minio
wait_minio_ready_and_bucket

start_web

# Foreground (keeps container alive)
start_museum_foreground
