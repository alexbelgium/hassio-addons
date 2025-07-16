#!/usr/bin/with-contenv bashio
# Generate museum.yaml (first boot) from add-on options
set -euo pipefail

CFG=/config/museum.yaml

if bashio::fs.file_exists "$CFG"; then
    bashio::log.info "Using existing $CFG"
    exit 0
fi

bashio::log.info "Generating $CFG"

# --- options ---
USE_EXTERNAL_DB=$(bashio::config.true 'USE_EXTERNAL_DB' && echo true || echo false)

DB_HOST="localhost"
DB_PORT=5432
DB_USER="$(bashio::config 'DB_USERNAME')"
DB_PASS="$(bashio::config 'DB_PASSWORD')"
DB_NAME="$(bashio::config 'DB_DATABASE_NAME')"

if ${USE_EXTERNAL_DB}; then
    # override host/port for external DB (fall back if missing)
    DB_HOST="$(bashio::config 'DB_HOSTNAME')"
    DB_PORT="$(bashio::config 'DB_PORT')"
    bashio::log.info "museum.yaml will point to external Postgres at ${DB_HOST}:${DB_PORT}"
else
    bashio::log.info "museum.yaml will use internal Postgres."
fi

MINIO_USER="$(bashio::config 'MINIO_ROOT_USER')"
MINIO_PASS="$(bashio::config 'MINIO_ROOT_PASSWORD')"
S3_BUCKET="$(bashio::config 'S3_BUCKET')"

# helpers
_random_b64() { head -c "$1" /dev/urandom | base64 | tr -d '\n'; }
_random_b64_url() { head -c "$1" /dev/urandom | base64 | tr '+/' '-_' | tr -d '\n'; }

cat >"$CFG" <<EOF
key:
  encryption: $(_random_b64 32)
  hash: $(_random_b64 64)

jwt:
  secret: $(_random_b64_url 32)

db:
  host: ${DB_HOST}
  port: ${DB_PORT}
  name: ${DB_NAME}
  user: ${DB_USER}
  password: ${DB_PASS}

s3:
  are_local_buckets: true
  b2-eu-cen:
     key: ${MINIO_USER}
     secret: ${MINIO_PASS}
     endpoint: localhost:3200
     region: eu-central-2
     bucket: ${S3_BUCKET}
EOF

bashio::log.info "Generated $CFG"
