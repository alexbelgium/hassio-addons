#!/usr/bin/env bashio
# shellcheck shell=bash

# Initialize variables
declare ABRP_TOKEN
declare ABRP_USER_TOKEN
declare MQTT_HOST
declare MQTT_PORT
declare MQTT_USERNAME
declare MQTT_PASSWORD

# Get config values
ABRP_TOKEN=$(bashio::config 'abrp_token')
ABRP_USER_TOKEN=$(bashio::config 'abrp_user_token')
MQTT_HOST=$(bashio::config 'mqtt_host')
MQTT_PORT=$(bashio::config 'mqtt_port')

# Export required variables
export ABRP_TOKEN
export ABRP_USER_TOKEN
export MQTT_HOST
export MQTT_PORT

# Optional MQTT authentication
if bashio::config.exists 'mqtt_username'; then
    MQTT_USERNAME=$(bashio::config 'mqtt_username')
    export MQTT_USERNAME
fi

if bashio::config.exists 'mqtt_password'; then
    MQTT_PASSWORD=$(bashio::config 'mqtt_password')
    export MQTT_PASSWORD
fi

bashio::log.info "Starting TeslaMate ABRP integration..."

# Change to app directory
cd /app || bashio::exit.nok "Failed to change to app directory"

# Start the Python script
exec python3 teslamate-abrp.py
