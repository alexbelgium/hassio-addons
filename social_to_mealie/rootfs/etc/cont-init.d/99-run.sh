#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

required_vars=(
    OPENAI_URL
    OPENAI_API_KEY
    TRANSCRIPTION_MODEL
    TEXT_MODEL
    MEALIE_URL
    MEALIE_API_KEY
)

for var in "${required_vars[@]}"; do
    if ! bashio::config.has_value "$var"; then
        bashio::exit.nok "Configuration option $var is required"
    fi
    export "$var"="$(bashio::config "$var")"
    bashio::log.info "$var configured"
done

optional_vars=(
    MEALIE_GROUP_NAME
    EXTRA_PROMPT
    YTDLP_VERSION
    COOKIES
)

for var in "${optional_vars[@]}"; do
    if bashio::config.has_value "$var"; then
        export "$var"="$(bashio::config "$var")"
        bashio::log.info "$var configured"
    fi
done

if bashio::config.has_value "env_vars"; then
    for entry in $(bashio::config 'env_vars | map(@base64) | .[]'); do
        item=$(echo "$entry" | base64 -d)
        name=$(echo "$item" | jq -r '.name // empty')
        value=$(echo "$item" | jq -r '.value // empty')
        if [ -n "$name" ]; then
            export "$name"="$value"
            bashio::log.info "Custom env $name configured"
        fi
    done
fi

bashio::log.info "Starting Social to Mealie"
cd /app || bashio::exit.nok "App directory not found"
exec /bin/sh /app/entrypoint.sh node --run start
