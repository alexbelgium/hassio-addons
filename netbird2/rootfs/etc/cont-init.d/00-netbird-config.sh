#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Configuring NetBird add-on"

DATA_PATH=$(bashio::config 'data_path')
DOMAIN=$(bashio::config 'domain')
LOG_LEVEL=$(bashio::config 'log_level')
MANAGEMENT_PORT=$(bashio::config 'management_port')
SIGNAL_PORT=$(bashio::config 'signal_port')
DASHBOARD_PORT=$(bashio::config 'dashboard_port')
MANAGEMENT_DNS_DOMAIN=$(bashio::config 'management_dns_domain')
SINGLE_ACCOUNT_DOMAIN=$(bashio::config 'single_account_domain')
AUTH_ISSUER=$(bashio::config 'auth_issuer')
AUTH_AUDIENCE=$(bashio::config 'auth_audience')
AUTH_JWT_CERTS=$(bashio::config 'auth_jwt_certs')
AUTH_USER_ID_CLAIM=$(bashio::config 'auth_user_id_claim')
AUTH_OIDC_CONFIGURATION_ENDPOINT=$(bashio::config 'auth_oidc_configuration_endpoint')
AUTH_CLIENT_ID=$(bashio::config 'auth_client_id')
AUTH_CLIENT_SECRET=$(bashio::config 'auth_client_secret')
AUTH_SUPPORTED_SCOPES=$(bashio::config 'auth_supported_scopes')
SSL_CERT=$(bashio::config 'ssl_cert')
SSL_KEY=$(bashio::config 'ssl_key')

mkdir -p "${DATA_PATH}"
mkdir -p /run/nginx

export NETBIRD_DOMAIN="${DOMAIN}"
export NETBIRD_LOG_LEVEL="${LOG_LEVEL}"
export NETBIRD_MGMT_API_PORT="${MANAGEMENT_PORT}"
export NETBIRD_SIGNAL_PORT="${SIGNAL_PORT}"
export NETBIRD_DASHBOARD_PORT="${DASHBOARD_PORT}"
export NETBIRD_SIGNAL_PROTOCOL="http"
export NETBIRD_DATA_DIR="${DATA_PATH}"
export NETBIRD_STORE_CONFIG_ENGINE="sqlite"
export NETBIRD_MGMT_DISABLE_DEFAULT_POLICY=$(bashio::config.true 'disable_default_policy' && echo true || echo false)

SCHEME="http"
if [[ -n "${SSL_CERT}" && -n "${SSL_KEY}" ]]; then
    export NETBIRD_MGMT_API_CERT_FILE="${SSL_CERT}"
    export NETBIRD_MGMT_API_CERT_KEY_FILE="${SSL_KEY}"
    SCHEME="https"
else
    export NETBIRD_MGMT_API_CERT_FILE=""
    export NETBIRD_MGMT_API_CERT_KEY_FILE=""
fi

export NETBIRD_AUTH_AUTHORITY="${AUTH_ISSUER}"
export NETBIRD_AUTH_AUDIENCE="${AUTH_AUDIENCE}"
export NETBIRD_AUTH_JWT_CERTS="${AUTH_JWT_CERTS}"
export NETBIRD_AUTH_USER_ID_CLAIM="${AUTH_USER_ID_CLAIM}"
export NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT="${AUTH_OIDC_CONFIGURATION_ENDPOINT}"

export NETBIRD_MGMT_API_ENDPOINT="${SCHEME}://${DOMAIN}:${MANAGEMENT_PORT}"
export NETBIRD_MGMT_GRPC_API_ENDPOINT="${SCHEME}://${DOMAIN}:${MANAGEMENT_PORT}"
export AUTH_AUTHORITY="${AUTH_ISSUER}"
export AUTH_AUDIENCE="${AUTH_AUDIENCE}"
export AUTH_CLIENT_ID="${AUTH_CLIENT_ID}"
export AUTH_CLIENT_SECRET="${AUTH_CLIENT_SECRET}"
export AUTH_SUPPORTED_SCOPES="${AUTH_SUPPORTED_SCOPES}"
export AUTH_REDIRECT_URI="https://${DOMAIN}:${DASHBOARD_PORT}/"
export AUTH_SILENT_REDIRECT_URI="https://${DOMAIN}:${DASHBOARD_PORT}/silent"

CONFIG_FILE="${DATA_PATH}/management.json"
if [[ ! -f "${CONFIG_FILE}" ]]; then
    bashio::log.warning "Generating a starter management.json in ${CONFIG_FILE}. Update OIDC settings before use."

    if [[ -z "${NETBIRD_DATASTORE_ENC_KEY}" ]]; then
        NETBIRD_DATASTORE_ENC_KEY=$(head -c 32 /dev/urandom | base64)
    fi
    export NETBIRD_DATASTORE_ENC_KEY

    envsubst '\$NETBIRD_SIGNAL_PROTOCOL \$NETBIRD_DOMAIN \$NETBIRD_SIGNAL_PORT \$NETBIRD_MGMT_DISABLE_DEFAULT_POLICY \$NETBIRD_DATA_DIR \$NETBIRD_DATASTORE_ENC_KEY \$NETBIRD_STORE_CONFIG_ENGINE \$NETBIRD_MGMT_API_PORT \$NETBIRD_AUTH_AUTHORITY \$NETBIRD_AUTH_AUDIENCE \$NETBIRD_AUTH_JWT_CERTS \$NETBIRD_AUTH_USER_ID_CLAIM \$NETBIRD_MGMT_API_CERT_FILE \$NETBIRD_MGMT_API_CERT_KEY_FILE \$NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT' \
        < /usr/share/netbird/management.json.tmpl > "${CONFIG_FILE}"
fi

#######################################
# Apply extra environment variables   #
#######################################

if jq -e '.env_vars? | length > 0' /data/options.json >/dev/null; then
    bashio::log.info "Applying env_vars"
    while IFS=$'\t' read -r ENV_NAME ENV_VALUE; do
        if [[ -z "${ENV_NAME}" || "${ENV_NAME}" == "null" ]]; then
            continue
        fi

        if [[ "${ENV_NAME}" == *"PASS"* || "${ENV_NAME}" == *"SECRET"* ]]; then
            bashio::log.blue "${ENV_NAME}=******"
        else
            bashio::log.blue "${ENV_NAME}=${ENV_VALUE}"
        fi

        export "${ENV_NAME}=${ENV_VALUE}"
    done < <(jq -r '.env_vars[] | [.name, .value] | @tsv' /data/options.json)
fi

bashio::log.info "NetBird data dir: ${DATA_PATH}"
bashio::log.info "Management DNS domain: ${MANAGEMENT_DNS_DOMAIN}"
if [[ -n "${SINGLE_ACCOUNT_DOMAIN}" ]]; then
    bashio::log.info "Single account domain: ${SINGLE_ACCOUNT_DOMAIN}"
fi
