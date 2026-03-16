#!/usr/bin/env bashio

bashio::log.info "Starting Immich Frame"

mkdir -p /config/Config
if [ -d /app/Config ] && [ ! -L /app/Config ]; then
    cp -n /app/Config/* /config/Config/ 2>/dev/null || true
    rm -rf /app/Config
fi
if [ ! -e /app/Config ]; then
    ln -sf /config/Config /app/Config
fi

# Generate Settings.yaml from addon options for multi-account support
SETTINGS_FILE="/config/Config/Settings.yaml"
ACCOUNT_COUNT=$(jq '.Accounts // [] | length' /data/options.json 2>/dev/null || echo 0)

if [ "$ACCOUNT_COUNT" -gt 0 ]; then
    bashio::log.info "Configuring ${ACCOUNT_COUNT} account(s) from Accounts list"
    {
        echo "Accounts:"
        for i in $(seq 0 $((ACCOUNT_COUNT - 1))); do
            SERVER_URL=$(jq -r ".Accounts[${i}].ImmichServerUrl" /data/options.json)
            API_KEY=$(jq -r ".Accounts[${i}].ApiKey" /data/options.json)
            # Escape single quotes for YAML single-quoted strings
            SERVER_URL="${SERVER_URL//\'/\'\'}"
            API_KEY="${API_KEY//\'/\'\'}"
            echo "  - ImmichServerUrl: '${SERVER_URL}'"
            echo "    ApiKey: '${API_KEY}'"
            bashio::log.info "  Account $((i + 1)): ${SERVER_URL}"
        done
    } > "${SETTINGS_FILE}"
    chmod 600 "${SETTINGS_FILE}"
    bashio::log.info "Settings.yaml generated at ${SETTINGS_FILE}"
elif bashio::config.has_value 'ApiKey' && bashio::config.has_value 'ImmichServerUrl'; then
    bashio::log.info "Using single account configuration"
    SERVER_URL=$(bashio::config 'ImmichServerUrl')
    API_KEY=$(bashio::config 'ApiKey')
    # Escape single quotes for YAML single-quoted strings
    SERVER_URL="${SERVER_URL//\'/\'\'}"
    API_KEY="${API_KEY//\'/\'\'}"
    {
        echo "Accounts:"
        echo "  - ImmichServerUrl: '${SERVER_URL}'"
        echo "    ApiKey: '${API_KEY}'"
    } > "${SETTINGS_FILE}"
    chmod 600 "${SETTINGS_FILE}"
    bashio::log.info "Settings.yaml generated at ${SETTINGS_FILE}"
else
    bashio::log.fatal "No accounts configured! Set either 'Accounts' list or both 'ApiKey' and 'ImmichServerUrl'"
    exit 1
fi

export IMMICHFRAME_CONFIG_PATH=/config/Config
exec dotnet ImmichFrame.WebApi.dll
