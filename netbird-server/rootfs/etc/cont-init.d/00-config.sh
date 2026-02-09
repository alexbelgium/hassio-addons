#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

# ==============================================================================
# Home Assistant Add-on: NetBird Server
# Configures NetBird services (quickstart layout)
# ==============================================================================

create_or_load_secret() {
  local secret_file="$1"
  local generator="$2"
  local generated=""

  if [[ -f "$secret_file" ]]; then
    cat "$secret_file"
    return
  fi

  generated=$(eval "$generator")
  echo "$generated" > "$secret_file"
  chmod 600 "$secret_file"
  echo "$generated"
}

DATA_DIR="/config/netbird"
DOMAIN="$(bashio::config 'domain')"
NETBIRD_STUN_PORT=3478
MANAGEMENT_PORT=8081
DASHBOARD_PORT=8080
SIGNAL_PORT=8083
SIGNAL_GRPC_PORT=10000
RELAY_PORT=8084

if [[ -z "$DOMAIN" || "$DOMAIN" == "netbird.example.com" ]]; then
  result=$(bashio::api.supervisor GET /core/api/config true || true)
  external_host="$(bashio::jq "$result" '.external_url' | cut -d'/' -f3 | cut -d':' -f1)"
  internal_host="$(bashio::jq "$result" '.internal_url' | cut -d'/' -f3 | cut -d':' -f1)"

  if [[ -n "$external_host" && "$external_host" != "null" ]]; then
    DOMAIN="$external_host"
    bashio::log.warning "Domain not set; using Home Assistant external_url host: ${DOMAIN}"
  elif [[ -n "$internal_host" && "$internal_host" != "null" ]]; then
    DOMAIN="$internal_host"
    bashio::log.warning "Domain not set; using Home Assistant internal_url host: ${DOMAIN}"
  else
    bashio::log.error "Set a valid domain in the add-on configuration (domain cannot be empty or netbird.example.com)."
    bashio::exit.nok
  fi
fi

NETBIRD_PORT=443
NETBIRD_HTTP_PROTOCOL="https"
NETBIRD_RELAY_PROTO="rels"
CADDY_SECURE_DOMAIN=", ${DOMAIN}:${NETBIRD_PORT}"

mkdir -p "$DATA_DIR" \
  "$DATA_DIR/management" \
  "$DATA_DIR/secrets" \
  "$DATA_DIR/dashboard" \
  "$DATA_DIR/relay" \
  "$DATA_DIR/caddy"

DATASTORE_ENC_KEY=$(create_or_load_secret "$DATA_DIR/secrets/management_datastore_key" "openssl rand -base64 32")
RELAY_AUTH_SECRET=$(create_or_load_secret "$DATA_DIR/secrets/relay_auth_secret" "openssl rand -base64 32 | sed 's/=//g'")

# Generate management config if missing
MANAGEMENT_CONFIG="$DATA_DIR/management/management.json"
if [[ ! -f "$MANAGEMENT_CONFIG" ]]; then
  bashio::log.info "Generating management config at ${MANAGEMENT_CONFIG}."
  cat <<CONFIG > "$MANAGEMENT_CONFIG"
{
  "Stuns": [
    {
      "Proto": "udp",
      "URI": "stun:${DOMAIN}:${NETBIRD_STUN_PORT}"
    }
  ],
  "Relay": {
    "Addresses": ["${NETBIRD_RELAY_PROTO}://${DOMAIN}:${NETBIRD_PORT}"],
    "CredentialsTTL": "24h",
    "Secret": "${RELAY_AUTH_SECRET}"
  },
  "Signal": {
    "Proto": "${NETBIRD_HTTP_PROTOCOL}",
    "URI": "${DOMAIN}:${NETBIRD_PORT}"
  },
  "Datadir": "${DATA_DIR}/management",
  "DataStoreEncryptionKey": "${DATASTORE_ENC_KEY}",
  "EmbeddedIdP": {
    "Enabled": true,
    "Issuer": "${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}/oauth2",
    "DashboardRedirectURIs": [
      "${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}/nb-auth",
      "${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}/nb-silent-auth"
    ]
  }
}
CONFIG
else
  bashio::log.info "Using existing management config at ${MANAGEMENT_CONFIG}."
fi

# Generate relay env file if missing
RELAY_ENV_FILE="$DATA_DIR/relay/relay.env"
if [[ ! -f "$RELAY_ENV_FILE" ]]; then
  bashio::log.info "Generating relay env file at ${RELAY_ENV_FILE}."
  cat <<CONFIG > "$RELAY_ENV_FILE"
NB_LOG_LEVEL=info
NB_LISTEN_ADDRESS=:${RELAY_PORT}
NB_EXPOSED_ADDRESS=${NETBIRD_RELAY_PROTO}://${DOMAIN}:${NETBIRD_PORT}
NB_AUTH_SECRET=${RELAY_AUTH_SECRET}
NB_ENABLE_STUN=true
NB_STUN_LOG_LEVEL=info
NB_STUN_PORTS=${NETBIRD_STUN_PORT}
CONFIG
fi

# Generate dashboard env file if missing
DASHBOARD_ENV_FILE="$DATA_DIR/dashboard/env"
if [[ ! -f "$DASHBOARD_ENV_FILE" ]]; then
  bashio::log.info "Generating dashboard env file at ${DASHBOARD_ENV_FILE}."
  cat <<CONFIG > "$DASHBOARD_ENV_FILE"
# Endpoints
NETBIRD_MGMT_API_ENDPOINT=${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}
NETBIRD_MGMT_GRPC_API_ENDPOINT=${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}
# OIDC - using embedded IdP
AUTH_AUDIENCE=netbird-dashboard
AUTH_CLIENT_ID=netbird-dashboard
AUTH_CLIENT_SECRET=
AUTH_AUTHORITY=${NETBIRD_HTTP_PROTOCOL}://${DOMAIN}/oauth2
USE_AUTH0=false
AUTH_SUPPORTED_SCOPES=openid profile email groups
AUTH_REDIRECT_URI=/nb-auth
AUTH_SILENT_REDIRECT_URI=/nb-silent-auth
# SSL
NGINX_SSL_PORT=443
# Letsencrypt
LETSENCRYPT_DOMAIN=none
CONFIG
  chmod 600 "$DASHBOARD_ENV_FILE"
fi

# Generate Caddyfile if missing
CADDYFILE="$DATA_DIR/Caddyfile"
if [[ ! -f "$CADDYFILE" ]]; then
  bashio::log.info "Generating Caddyfile at ${CADDYFILE}."
  cat <<CONFIG > "$CADDYFILE"
{
  servers {
    protocols h1 h2 h2c
  }
}

(security_headers) {
  header * {
    Strict-Transport-Security "max-age=3600; includeSubDomains; preload"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "SAMEORIGIN"
    X-XSS-Protection "1; mode=block"
    -Server
    Referrer-Policy strict-origin-when-cross-origin
  }
}

:80${CADDY_SECURE_DOMAIN} {
  import security_headers
  # relay
  reverse_proxy /relay* 127.0.0.1:${RELAY_PORT}
  # Signal
  reverse_proxy /ws-proxy/signal* 127.0.0.1:${SIGNAL_PORT}
  reverse_proxy /signalexchange.SignalExchange/* h2c://127.0.0.1:${SIGNAL_GRPC_PORT}
  # Management
  reverse_proxy /api/* 127.0.0.1:${MANAGEMENT_PORT}
  reverse_proxy /ws-proxy/management* 127.0.0.1:${MANAGEMENT_PORT}
  reverse_proxy /management.ManagementService/* h2c://127.0.0.1:${MANAGEMENT_PORT}
  reverse_proxy /oauth2/* 127.0.0.1:${MANAGEMENT_PORT}
  # Dashboard
  reverse_proxy /* 127.0.0.1:${DASHBOARD_PORT}
}
CONFIG
else
  bashio::log.info "Using existing Caddyfile at ${CADDYFILE}."
fi

mkdir -p /run/nginx
chmod +x /usr/local/bin/init_react_envs.sh
