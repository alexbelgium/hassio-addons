#!/usr/bin/env bash
# shellcheck shell=bash
set -Eeuo pipefail

# Obsidian LiveSync sync server (CouchDB) as a Home Assistant add-on.
#
# CouchDB alone is not usable as a LiveSync backend: the plugin needs a
# single-node cluster, CORS opened to Obsidian's app origins, authentication
# required, and raised request/document size limits. This script applies that
# configuration on every start. The settings mirror the upstream provisioning
# tool (vrtmrz/obsidian-livesync, utils/couchdb/provision.ts), which is the
# authoritative source for what LiveSync expects.

OPTIONS_JSON="/data/options.json"
ADDON_DIR="/config/obsidian-syncserver"
PASSWORD_FILE="${ADDON_DIR}/admin_password"
DATA_DIR="${ADDON_DIR}/data"
LOCAL_D="/opt/couchdb/etc/local.d"
COUCH_URL="http://127.0.0.1:5984"

# Retry budget matches provision.ts: CouchDB on a Raspberry Pi can take a
# while to open its listener on first boot.
READY_RETRIES=12
READY_DELAY=5

log() { echo "[obsidian-syncserver] $*"; }
warn() { echo "[obsidian-syncserver] WARN: $*" >&2; }
die() {
    echo "[obsidian-syncserver] ERROR: $*" >&2
    exit 1
}

read_opt() {
    jq -er --arg k "$1" '.[$k]' "$OPTIONS_JSON" 2> /dev/null || true
}

# ---------------------------------------------------------------------------
# Step 1: Read add-on options
# ---------------------------------------------------------------------------
[[ -f "$OPTIONS_JSON" ]] || die "Missing options file at ${OPTIONS_JSON}"

USERNAME="$(read_opt username)"
USERNAME="${USERNAME:-admin}"
PASSWORD="$(read_opt password)"
DATABASE="$(read_opt database)"
DATABASE="${DATABASE:-obsidian}"
LOG_LEVEL="$(read_opt log_level)"
LOG_LEVEL="${LOG_LEVEL:-info}"

# CouchDB database names are restricted; a bad name only fails much later at
# the create step, with an opaque 400.
[[ "$DATABASE" =~ ^[a-z][a-z0-9_$()+/-]*$ ]] \
    || die "database '${DATABASE}' is invalid. Must start with a lowercase letter and contain only a-z 0-9 _ \$ ( ) + / -"

mkdir -p "$ADDON_DIR"

# ---------------------------------------------------------------------------
# Step 2: Resolve admin credentials
#
# A blank password auto-generates one and persists it, so the add-on never
# ships a guessable default. It is reused on later starts, otherwise every
# restart would invalidate the credentials already configured in Obsidian.
# ---------------------------------------------------------------------------
if [[ -z "$PASSWORD" ]]; then
    if [[ -f "$PASSWORD_FILE" ]]; then
        PASSWORD="$(cat "$PASSWORD_FILE")"
        log "Using previously generated admin password from ${PASSWORD_FILE}"
    else
        PASSWORD="$(openssl rand -base64 24)"
        (
            umask 077
            printf '%s\n' "$PASSWORD" > "$PASSWORD_FILE"
        )
        warn "No password set. Generated one and saved it to ${PASSWORD_FILE}"
        warn "Admin username: ${USERNAME}"
        warn "Admin password: ${PASSWORD}"
        warn "Set a password in the add-on options to choose your own."
    fi
fi

export COUCHDB_USER="$USERNAME"
export COUCHDB_PASSWORD="$PASSWORD"

# ---------------------------------------------------------------------------
# Step 3: Point CouchDB at persistent storage
#
# /data is wiped when the add-on is reinstalled, and is not included in a
# Home Assistant backup the way the add-on config directory is. The vault is
# the whole point of this add-on, so it lives under /config instead.
# ---------------------------------------------------------------------------
mkdir -p "$DATA_DIR" "${DATA_DIR}/.delayed" "$LOCAL_D"

COUCH_UID="$(id -u couchdb 2> /dev/null || echo 5984)"
COUCH_GID="$(id -g couchdb 2> /dev/null || echo 5984)"
chown -R "${COUCH_UID}:${COUCH_GID}" "$ADDON_DIR" 2> /dev/null \
    || warn "Could not chown ${ADDON_DIR}; CouchDB may fail to write to it"

cat > "${LOCAL_D}/10-addon-storage.ini" << EOF
; Managed by the Home Assistant add-on. Edits are overwritten on restart.
[couchdb]
database_dir = ${DATA_DIR}
view_index_dir = ${DATA_DIR}

[chttpd]
bind_address = 0.0.0.0
port = 5984

[log]
level = ${LOG_LEVEL}
EOF

# Flavour hook: _ssl overrides this to write 20-addon-ssl.ini after validating
# the user's certificates. No-op in this flavour.
if declare -f configure_tls > /dev/null 2>&1; then
    configure_tls
fi

# ---------------------------------------------------------------------------
# Step 4: Start CouchDB in the background
# ---------------------------------------------------------------------------
log "Starting CouchDB (user=${USERNAME}, database=${DATABASE}, log_level=${LOG_LEVEL})"
/docker-entrypoint.sh /opt/couchdb/bin/couchdb &
COUCH_PID=$!

# Without this, a CouchDB that dies during provisioning leaves the script
# retrying against a socket that will never come up.
trap 'kill -TERM "$COUCH_PID" 2>/dev/null || true' EXIT INT TERM

# ---------------------------------------------------------------------------
# Step 5: Wait for CouchDB to accept requests
# ---------------------------------------------------------------------------
ready=false
for i in $(seq 1 "$READY_RETRIES"); do
    if curl -fsS -u "${USERNAME}:${PASSWORD}" "${COUCH_URL}/_up" > /dev/null 2>&1; then
        ready=true
        break
    fi
    kill -0 "$COUCH_PID" 2> /dev/null || die "CouchDB exited during startup. See the log above."
    log "Waiting for CouchDB to come up (${i}/${READY_RETRIES})"
    sleep "$READY_DELAY"
done
[[ "$ready" == "true" ]] || die "CouchDB did not become ready after $((READY_RETRIES * READY_DELAY))s"

log "CouchDB is up, applying Obsidian LiveSync configuration"

# ---------------------------------------------------------------------------
# Step 6: Provision for LiveSync
#
# Every call below is idempotent, so this runs safely on each start and
# repairs configuration that was changed by hand in Fauxton.
# ---------------------------------------------------------------------------

# Promotes the single node out of the uninitialised state. A node that is
# already set up answers 400/409 with "already"/"finished", which is success
# here, not an error.
cluster_body="$(jq -nc \
    --arg u "$USERNAME" --arg p "$PASSWORD" \
    '{action:"enable_single_node",username:$u,password:$p,bind_address:"0.0.0.0",port:5984,singlenode:true}')"

cluster_response="$(curl -sS -u "${USERNAME}:${PASSWORD}" \
    -X POST "${COUCH_URL}/_cluster_setup" \
    -H "Content-Type: application/json" \
    -d "$cluster_body" \
    -w '\n%{http_code}' 2>&1 || true)"
cluster_code="$(printf '%s' "$cluster_response" | tail -n1)"
cluster_text="$(printf '%s' "$cluster_response" | sed '$d')"

case "$cluster_code" in
    2*) log "Single-node cluster initialised" ;;
    400 | 409)
        if printf '%s' "$cluster_text" | rg -qi 'already|finished'; then
            log "Single-node cluster already initialised"
        else
            die "Cluster setup failed (HTTP ${cluster_code}): ${cluster_text}"
        fi
        ;;
    *) die "Cluster setup failed (HTTP ${cluster_code}): ${cluster_text}" ;;
esac

# CORS origins are what let the Obsidian desktop app and the mobile app talk
# to CouchDB at all; without them the plugin fails with an opaque network
# error. Values are taken from provision.ts.
set_config() {
    local label="$1" key="$2" value="$3" code
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        -u "${USERNAME}:${PASSWORD}" \
        -X PUT "${COUCH_URL}/_node/_local/_config/${key}" \
        -H "Content-Type: application/json" \
        -d "$value" 2>&1 || true)"
    case "$code" in
        2*) log "  set ${label}" ;;
        *) die "Failed to ${label} (HTTP ${code}) at ${key}" ;;
    esac
}

set_config "require authenticated HTTP users" "chttpd/require_valid_user" '"true"'
set_config "require authenticated HTTP users for authentication" "chttpd_auth/require_valid_user" '"true"'
set_config "the HTTP authentication challenge" "httpd/WWW-Authenticate" '"Basic realm=\"couchdb\""'
set_config "enable HTTP CORS" "httpd/enable_cors" '"true"'
set_config "enable clustered HTTP CORS" "chttpd/enable_cors" '"true"'
set_config "the maximum HTTP request size" "chttpd/max_http_request_size" '"4294967296"'
set_config "the maximum document size" "couchdb/max_document_size" '"50000000"'
set_config "enable CORS credentials" "cors/credentials" '"true"'
set_config "allowed CORS origins" "cors/origins" '"app://obsidian.md,capacitor://localhost,http://localhost"'

# 412 means the database is already there, which is the normal case on every
# start after the first.
db_code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -u "${USERNAME}:${PASSWORD}" \
    -X PUT "${COUCH_URL}/$(printf '%s' "$DATABASE" | jq -sRr @uri)" 2>&1 || true)"
case "$db_code" in
    2*) log "Created database '${DATABASE}'" ;;
    412) log "Database '${DATABASE}' already exists" ;;
    *) die "Failed to create database '${DATABASE}' (HTTP ${db_code})" ;;
esac

log "Ready. Point Obsidian Self-hosted LiveSync at this server."
log "  database: ${DATABASE}   username: ${USERNAME}"

# ---------------------------------------------------------------------------
# Step 7: Hand the container's lifetime back to CouchDB
# ---------------------------------------------------------------------------
trap - EXIT
wait "$COUCH_PID"
