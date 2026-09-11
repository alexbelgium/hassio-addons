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
SSL_ENABLED="$(read_opt ssl)"
SSL_ENABLED="${SSL_ENABLED:-true}"
CERTFILE="$(read_opt certfile)"
CERTFILE="${CERTFILE:-fullchain.pem}"
KEYFILE="$(read_opt keyfile)"
KEYFILE="${KEYFILE:-privkey.pem}"

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

# ---------------------------------------------------------------------------
# Step 3b: Configure native TLS
#
# A certificate problem here surfaces on the client as an opaque "cannot
# connect" — mobile Obsidian gives no detail about why it rejected the
# server. So every failure mode is checked up front and reported with the
# specific cause, rather than starting a listener clients will refuse.
# ---------------------------------------------------------------------------
SSL_INI="${LOCAL_D}/20-addon-ssl.ini"
rm -f "$SSL_INI"

if [[ "$SSL_ENABLED" == "true" ]]; then
    CERT_PATH="/ssl/${CERTFILE#/ssl/}"
    KEY_PATH="/ssl/${KEYFILE#/ssl/}"

    [[ -f "$CERT_PATH" ]] || die "certfile not found at ${CERT_PATH}. Check the certfile option, or set ssl to false."
    [[ -r "$CERT_PATH" ]] || die "certfile at ${CERT_PATH} is not readable."
    [[ -f "$KEY_PATH" ]] || die "keyfile not found at ${KEY_PATH}. Check the keyfile option, or set ssl to false."
    [[ -r "$KEY_PATH" ]] || die "keyfile at ${KEY_PATH} is not readable."

    openssl x509 -in "$CERT_PATH" -noout > /dev/null 2>&1 \
        || die "certfile at ${CERT_PATH} is not a valid PEM certificate."
    openssl pkey -in "$KEY_PATH" -noout > /dev/null 2>&1 \
        || die "keyfile at ${KEY_PATH} is not a valid PEM private key."

    # An expired certificate is the most common cause of "it worked last
    # month and now my phone will not sync".
    if ! openssl x509 -in "$CERT_PATH" -checkend 0 -noout > /dev/null 2>&1; then
        not_after="$(openssl x509 -in "$CERT_PATH" -noout -enddate 2> /dev/null | cut -d= -f2-)"
        die "certfile at ${CERT_PATH} expired on ${not_after}. Renew it, or set ssl to false to serve HTTP only."
    fi

    # A mismatched pair starts fine and then fails every handshake.
    cert_pub="$(openssl x509 -in "$CERT_PATH" -noout -pubkey 2> /dev/null | openssl md5 2> /dev/null)"
    key_pub="$(openssl pkey -in "$KEY_PATH" -pubout 2> /dev/null | openssl md5 2> /dev/null)"
    [[ -n "$cert_pub" && "$cert_pub" == "$key_pub" ]] \
        || die "certfile and keyfile do not match — ${CERTFILE} was not issued for ${KEYFILE}."

    # Warn only: hostname detection is best effort, and a mismatch is
    # legitimate when reaching the server by an alternate name.
    san="$(openssl x509 -in "$CERT_PATH" -noout -ext subjectAltName 2> /dev/null | rg -o 'DNS:[^,]+' | sed 's/DNS://' | tr '\n' ' ' || true)"
    if [[ -n "$san" ]]; then
        log "Certificate covers: ${san}"
        log "Obsidian must reach this server by one of those names, or it will reject the certificate."
    fi

    expires="$(openssl x509 -in "$CERT_PATH" -noout -enddate 2> /dev/null | cut -d= -f2-)"
    log "TLS enabled on port 6984 (certificate valid until ${expires})"

    cat > "$SSL_INI" << EOF
; Managed by the Home Assistant add-on. Edits are overwritten on restart.
[ssl]
enable = true
cert_file = ${CERT_PATH}
key_file = ${KEY_PATH}
port = 6984
bind_address = 0.0.0.0
EOF
else
    warn "TLS is disabled. Mobile Obsidian requires HTTPS and will not be able to sync."
    warn "Set ssl to true with a valid certificate in /ssl to enable it."
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
