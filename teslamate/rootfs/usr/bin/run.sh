#!/usr/bin/env bashio
# shellcheck shell=bash

# Declare variables
declare database_host
declare database_name
declare database_user
declare database_pass
declare database_port
declare mqtt_host
declare mqtt_username
declare mqtt_password
declare timezone
declare language
declare log_level

# Get config values with defaults
database_host=$(bashio::config 'database_host')
database_name=$(bashio::config 'database_name' 'teslamate')
database_user=$(bashio::config 'database_user' 'teslamate')
database_pass=$(bashio::config 'database_pass' 'teslamate')
database_port=$(bashio::config 'database_port' '5432')
mqtt_host=$(bashio::config 'mqtt_host' 'core-mosquitto')
mqtt_username=$(bashio::config 'mqtt_username' '')
mqtt_password=$(bashio::config 'mqtt_password' '')
timezone=$(bashio::config 'timezone' 'UTC')
language=$(bashio::config 'language' 'en')
log_level=$(bashio::config 'log_level' 'info')

# Export required environment variables
export DATABASE_HOST="${database_host}"
export DATABASE_NAME="${database_name}"
export DATABASE_USER="${database_user}"
export DATABASE_PASS="${database_pass}"
export DATABASE_PORT="${database_port}"
export MQTT_HOST="${mqtt_host}"
export MQTT_USERNAME="${mqtt_username}"
export MQTT_PASSWORD="${mqtt_password}"
export TZ="${timezone}"
export LOCALE="${language}"
export LOG_LEVEL="${log_level}"

# Optional configurations
if bashio::config.true 'disable_mqtt'; then
    export DISABLE_MQTT=true
fi

if bashio::config.true 'disable_sleep_mode'; then
    export DISABLE_SLEEP_MODE=true
fi

if bashio::config.true 'enable_send_push_notifications'; then
    export ENABLE_SEND_PUSH_NOTIFICATIONS=true
fi

if bashio::config.true 'disable_api_access'; then
    export DISABLE_API_ACCESS=true
fi

bashio::log.info "Starting TeslaMate..."

# Start TeslaMate
cd /opt/teslamate || bashio::exit.nok "Failed to change directory to TeslaMate"
exec /opt/teslamate/_build/prod/rel/teslamate/bin/teslamate start
