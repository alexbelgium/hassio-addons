#!/usr/bin/env bashio
# shellcheck shell=bash

# Internal MinIO credentials (not user-configurable; MinIO is 127.0.0.1 only)
MINIO_CRED_FILE="/config/minio-creds"
if [ -f "$MINIO_CRED_FILE" ]; then
    # Reuse persisted credentials across restarts
    MINIO_USER="$(sed -n '1p' "$MINIO_CRED_FILE")"
    MINIO_PASS="$(sed -n '2p' "$MINIO_CRED_FILE")"
    # Regenerate if file is corrupted
    if [ -z "$MINIO_USER" ] || [ -z "$MINIO_PASS" ]; then
        MINIO_USER="minio_$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8 || true)"
        MINIO_PASS="$(head -c 24 /dev/urandom | base64 | tr -d '\n')"
        printf '%s\n%s\n' "$MINIO_USER" "$MINIO_PASS" > "$MINIO_CRED_FILE"
        chmod 600 "$MINIO_CRED_FILE"
    fi
else
    # Generate random credentials on first run
    MINIO_USER="minio_$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8 || true)"
    MINIO_PASS="$(head -c 24 /dev/urandom | base64 | tr -d '\n')"
    printf '%s\n%s\n' "$MINIO_USER" "$MINIO_PASS" > "$MINIO_CRED_FILE"
    chmod 600 "$MINIO_CRED_FILE"
fi
S3_BUCKET="b2-eu-cen"

export ENTE_S3_ARE_LOCAL_BUCKETS=true
export ENTE_S3_B2_EU_CEN_KEY="$MINIO_USER"
export ENTE_S3_B2_EU_CEN_SECRET="$MINIO_PASS"
export ENTE_S3_B2_EU_CEN_ENDPOINT="http://127.0.0.1:3200"
export ENTE_S3_B2_EU_CEN_REGION=eu-central-2
export ENTE_S3_B2_EU_CEN_BUCKET="$S3_BUCKET"

############################################
# Paths & constants
############################################
CFG=/config/museum.yaml
PGDATA=/config/postgres

# Internal Postgres always bound here
DB_HOST_INTERNAL=127.0.0.1
DB_PORT_INTERNAL=5432

############################################
# Read add‑on options
############################################
DB_NAME="$(bashio::config 'DB_DATABASE_NAME' || echo ente_db)"
DB_USER="$(bashio::config 'DB_USERNAME' || echo pguser)"
DB_PASS="$(bashio::config 'DB_PASSWORD' || echo ente)"

# External DB opts (may be blank)
DB_HOST_EXT="$(bashio::config 'DB_HOSTNAME' || echo '')"
DB_PORT_EXT="$(bashio::config 'DB_PORT' || echo '')"
# Default external Postgres port when unset
[ -z "$DB_PORT_EXT" ] && DB_PORT_EXT=5432

USE_EXTERNAL_DB=false
if bashio::config.true 'USE_EXTERNAL_DB'; then
    USE_EXTERNAL_DB=true
    bashio::log.warning "USE_EXTERNAL_DB enabled: will connect to external Postgres."
else
    bashio::log.info "Using internal Postgres."
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
    /config/minio-data \
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
[ -z "$MUSEUM_BIN" ] && MUSEUM_BIN=museum # fallback in PATH

############################################
# Config generation
############################################
create_config() {
    bashio::log.info "Generating new museum config at $CFG"
    _rand_b64() { head -c "$1" /dev/urandom | base64 | tr -d '\n'; }
    _rand_b64url() { head -c "$1" /dev/urandom | base64 | tr '+/' '-_' | tr -d '\n'; }

    cat > "$CFG" << EOF
key:
  encryption: $(_rand_b64 32)
  hash:       $(_rand_b64 64)

jwt:
  secret: $(_rand_b64url 32)

db:
  host:     ${DB_HOST}
  port:     ${DB_PORT}
  name:     ${DB_NAME}
  user:     ${DB_USER}
  password: ${DB_PASS}

s3:
  are_local_buckets: true
  ${S3_BUCKET}:
    key:      ${MINIO_USER}
    secret:   ${MINIO_PASS}
    endpoint: ${ENTE_S3_B2_EU_CEN_ENDPOINT}
    region:   ${ENTE_S3_B2_EU_CEN_REGION}
    bucket:   ${S3_BUCKET}
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
        host="$DB_HOST_EXT"
        port="$DB_PORT_EXT"
        bashio::log.info "Waiting for EXTERNAL Postgres at ${host}:${port}..."
    else
        host="$DB_HOST_INTERNAL"
        port="$DB_PORT_INTERNAL"
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
    bashio::log.info "Starting MinIO (127.0.0.1:3200)..."
    mkdir -p /config/minio-data
    export MINIO_ROOT_USER="$MINIO_USER"
    export MINIO_ROOT_PASSWORD="$MINIO_PASS"
    "$MINIO_BIN" server /config/minio-data --address "127.0.0.1:3200" --console-address "127.0.0.1:9001" &
    MINIO_PID=$!
}

wait_minio_ready_and_bucket() {
    bashio::log.info "Waiting for MinIO API..."
    until "$MC_BIN" alias set h0 http://127.0.0.1:3200 "$MINIO_USER" "$MINIO_PASS" 2> /dev/null; do
        sleep 1
    done
    bashio::log.info "Ensuring buckets..."
    "$MC_BIN" mb -p "h0/${S3_BUCKET}" || true
    bashio::log.info "MinIO buckets ready."
}

############################################
# Web (static nginx bundle)
############################################
start_web() {
    ENTE_API_ORIGIN="$(bashio::config 'ENTE_ENDPOINT_URL')"
    # Derive albums origin from the same host as the API endpoint, mapped to port 8302
    ENTE_ALBUMS_HOST="$(echo "$ENTE_API_ORIGIN" | sed -E 's#(https?://[^:/]+).*#\1#')"
    ENTE_ALBUMS_ORIGIN="${ENTE_ALBUMS_HOST}:8302"
    export ENTE_API_ORIGIN ENTE_ALBUMS_ORIGIN

    # Running ente-web-prepare
    echo "[ente-web-prepare] Substituting origins…"
    find /www -name '*.js' | xargs sed -i "s#ENTE_API_ORIGIN_PLACEHOLDER#${ENTE_API_ORIGIN}#g"
    find /www/photos -name '*.js' | xargs sed -i "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#${ENTE_ALBUMS_ORIGIN}#g"

    mkdir -p /run/nginx /var/log/nginx

    # Set nginx (idempotent: only move if .bak still exists)
    if [ -f /etc/nginx/http.d/web.bak ]; then
        mv /etc/nginx/http.d/web.bak /etc/nginx/http.d/web.conf
    fi

    bashio::log.info "Starting Ente web (nginx, ports 3000‑3009)..."
    nginx -g 'daemon off;' &
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
    if [ ! -x "$MUSEUM_BIN" ] && ! command -v "$MUSEUM_BIN" > /dev/null 2>&1; then
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

# Foreground — keeps container alive
start_museum_foreground
