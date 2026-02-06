#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

# ==============================================================================
# Home Assistant Add-on: NetBird Server
# Configures NetBird services
# ==============================================================================

create_or_load_secret() {
  local secret_file="$1"
  local provided_value="$2"
  local generated=""

  if [[ -n "$provided_value" ]]; then
    echo "$provided_value"
    return
  fi

  if [[ -f "$secret_file" ]]; then
    cat "$secret_file"
    return
  fi

  generated=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
  echo "$generated" > "$secret_file"
  chmod 600 "$secret_file"
  echo "$generated"
}

extract_port() {
  local address="$1"
  echo "${address##*:}"
}

DATA_DIR=$(bashio::config 'data_dir')
DOMAIN=$(bashio::config 'domain')
EXTERNAL_BASE_URL=$(bashio::config 'external_base_url')
MANAGEMENT_LISTEN=$(bashio::config 'management_listen')
SIGNAL_LISTEN=$(bashio::config 'signal_listen')
DASHBOARD_LISTEN=$(bashio::config 'dashboard_listen')
TURN_LISTEN_PORT=$(bashio::config 'turn_listen_port')
TURN_REALM=$(bashio::config 'turn_realm')
TURN_EXTERNAL_IP=$(bashio::config 'turn_external_ip')
TURN_MIN_PORT=$(bashio::config 'turn_min_port')
TURN_MAX_PORT=$(bashio::config 'turn_max_port')
TURN_USER=$(bashio::config 'turn_user')
TURN_PASSWORD=$(bashio::config 'turn_password')
IDP_MANAGER_TYPE=$(bashio::config 'idp_manager_type')
AUTH_AUTHORITY=$(bashio::config 'auth_authority')
AUTH_AUDIENCE=$(bashio::config 'auth_audience')
AUTH_JWT_CERTS=$(bashio::config 'auth_jwt_certs')
AUTH_USER_ID_CLAIM=$(bashio::config 'auth_user_id_claim')
AUTH_OIDC_CONFIGURATION_ENDPOINT=$(bashio::config 'auth_oidc_configuration_endpoint')
AUTH_TOKEN_ENDPOINT=$(bashio::config 'auth_token_endpoint')
IDP_CLIENT_ID=$(bashio::config 'idp_client_id')
IDP_CLIENT_SECRET=$(bashio::config 'idp_client_secret')
DISABLE_DEFAULT_POLICY=$(bashio::config 'disable_default_policy')
DISABLE_DASHBOARD=$(bashio::config 'disable_dashboard')
ENABLE_RELAY=$(bashio::config 'enable_relay')
RELAY_EXPOSED_ADDRESS=$(bashio::config 'relay_exposed_address')
RELAY_AUTH_SECRET=$(bashio::config 'relay_auth_secret')

MANAGEMENT_PORT=$(extract_port "$MANAGEMENT_LISTEN")
SIGNAL_PORT=$(extract_port "$SIGNAL_LISTEN")
DASHBOARD_PORT=$(extract_port "$DASHBOARD_LISTEN")

if [[ -z "$DOMAIN" ]]; then
  DOMAIN="localhost"
  bashio::log.warning "domain is empty; defaulting to localhost in generated configs."
fi

if [[ -z "$AUTH_AUTHORITY" || -z "$AUTH_AUDIENCE" || -z "$AUTH_JWT_CERTS" ]]; then
  bashio::log.warning "OIDC configuration is incomplete. Update auth_* options or edit ${DATA_DIR}/management/management.json."
fi

mkdir -p "$DATA_DIR" \
  "$DATA_DIR/management" \
  "$DATA_DIR/turn" \
  "$DATA_DIR/secrets" \
  "$DATA_DIR/dashboard" \
  "$DATA_DIR/relay"

TURN_PASSWORD=$(create_or_load_secret "$DATA_DIR/secrets/turn_password" "$TURN_PASSWORD")
TURN_SECRET=$(create_or_load_secret "$DATA_DIR/secrets/turn_secret" "")
DATASTORE_ENC_KEY=$(create_or_load_secret "$DATA_DIR/secrets/management_datastore_key" "")

if [[ "$ENABLE_RELAY" == "true" ]]; then
  if [[ -z "$RELAY_EXPOSED_ADDRESS" || -z "$RELAY_AUTH_SECRET" ]]; then
    bashio::log.error "Relay is enabled, but relay_exposed_address or relay_auth_secret is missing."
    bashio::exit.nok
  fi
  rm -f /etc/services.d/relay/down
  RELAY_JSON=$(cat <<RELAY
{
  "Addresses": ["${RELAY_EXPOSED_ADDRESS}"],
  "CredentialsTTL": "24h",
  "Secret": "${RELAY_AUTH_SECRET}"
}
RELAY
)
else
  bashio::log.info "Relay service disabled."
  touch /etc/services.d/relay/down
  RELAY_JSON="null"
fi

if [[ "$DISABLE_DASHBOARD" == "true" ]]; then
  bashio::log.info "Dashboard service disabled."
  touch /etc/services.d/dashboard/down
else
  rm -f /etc/services.d/dashboard/down
fi

# Generate management config if missing
MANAGEMENT_CONFIG="$DATA_DIR/management/management.json"
if [[ ! -f "$MANAGEMENT_CONFIG" ]]; then
  bashio::log.info "Generating management config at ${MANAGEMENT_CONFIG}."
  cat <<CONFIG > "$MANAGEMENT_CONFIG"
{
  "Stuns": [
    {
      "Proto": "udp",
      "URI": "stun:${DOMAIN}:${TURN_LISTEN_PORT}",
      "Username": "",
      "Password": null
    }
  ],
  "TURNConfig": {
    "Turns": [
      {
        "Proto": "udp",
        "URI": "turn:${DOMAIN}:${TURN_LISTEN_PORT}",
        "Username": "${TURN_USER}",
        "Password": "${TURN_PASSWORD}"
      }
    ],
    "CredentialsTTL": "12h",
    "Secret": "${TURN_SECRET}",
    "TimeBasedCredentials": false
  },
  "Relay": ${RELAY_JSON},
  "Signal": {
    "Proto": "http",
    "URI": "${DOMAIN}:${SIGNAL_PORT}",
    "Username": "",
    "Password": null
  },
  "ReverseProxy": {
    "TrustedHTTPProxies": [],
    "TrustedHTTPProxiesCount": 0,
    "TrustedPeers": [
      "0.0.0.0/0"
    ]
  },
  "DisableDefaultPolicy": ${DISABLE_DEFAULT_POLICY},
  "Datadir": "${DATA_DIR}/management",
  "DataStoreEncryptionKey": "${DATASTORE_ENC_KEY}",
  "StoreConfig": {
    "Engine": "sqlite"
  },
  "HttpConfig": {
    "Address": "${MANAGEMENT_LISTEN}",
    "AuthIssuer": "${AUTH_AUTHORITY}",
    "AuthAudience": "${AUTH_AUDIENCE}",
    "AuthKeysLocation": "${AUTH_JWT_CERTS}",
    "AuthUserIDClaim": "${AUTH_USER_ID_CLAIM}",
    "CertFile": "",
    "CertKey": "",
    "IdpSignKeyRefreshEnabled": false,
    "OIDCConfigEndpoint": "${AUTH_OIDC_CONFIGURATION_ENDPOINT}"
  },
  "IdpManagerConfig": {
    "ManagerType": "${IDP_MANAGER_TYPE}",
    "ClientConfig": {
      "Issuer": "${AUTH_AUTHORITY}",
      "TokenEndpoint": "${AUTH_TOKEN_ENDPOINT}",
      "ClientID": "${IDP_CLIENT_ID}",
      "ClientSecret": "${IDP_CLIENT_SECRET}",
      "GrantType": "client_credentials"
    },
    "ExtraConfig": {}
  }
}
CONFIG
else
  bashio::log.info "Using existing management config at ${MANAGEMENT_CONFIG}."
fi

# Generate Coturn config if missing
TURN_CONFIG="$DATA_DIR/turn/turnserver.conf"
if [[ ! -f "$TURN_CONFIG" ]]; then
  TURN_EXTERNAL_IP_LINE=""
  if [[ -n "$TURN_EXTERNAL_IP" ]]; then
    TURN_EXTERNAL_IP_LINE="external-ip=${TURN_EXTERNAL_IP}"
  fi

  cat <<CONFIG > "$TURN_CONFIG"
listening-port=${TURN_LISTEN_PORT}
realm=${TURN_REALM}
fingerprint
lt-cred-mech
user=${TURN_USER}:${TURN_PASSWORD}
${TURN_EXTERNAL_IP_LINE}
min-port=${TURN_MIN_PORT}
max-port=${TURN_MAX_PORT}
CONFIG
else
  bashio::log.info "Using existing Coturn config at ${TURN_CONFIG}."
fi

# Generate dashboard nginx config
sed "s/__DASHBOARD_PORT__/${DASHBOARD_PORT}/g" \
  /usr/local/share/netbird-dashboard/default.conf.tmpl \
  > /etc/nginx/http.d/default.conf

mkdir -p /run/nginx
chmod +x /usr/local/bin/init_react_envs.sh
