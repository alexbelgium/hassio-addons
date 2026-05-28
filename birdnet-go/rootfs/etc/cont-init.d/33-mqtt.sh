#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# If the Home Assistant MQTT addon is active, wire its credentials directly
# into BirdNET-Go's config.yaml (upstream reads MQTT settings only from YAML;
# no env-var overrides exist). Users who prefer to manage MQTT manually can
# set mqtt_disable: true in the addon options.

CONFIG_LOCATION="/config/config.yaml"

if ! bashio::services.available 'mqtt'; then
    exit 0
fi

if bashio::config.true 'mqtt_disable'; then
    bashio::log.info "MQTT auto-configuration disabled by 'mqtt_disable' addon option; skipping."
    exit 0
fi

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "Skipping MQTT auto-configuration: $CONFIG_LOCATION not found"
    exit 0
fi

MQTT_HOST="$(bashio::services 'mqtt' 'host')"
MQTT_PORT="$(bashio::services 'mqtt' 'port')"
MQTT_USER="$(bashio::services 'mqtt' 'username')"
MQTT_PASS="$(bashio::services 'mqtt' 'password')"
MQTT_BROKER="tcp://${MQTT_HOST}:${MQTT_PORT}"

bashio::log.green "---"
bashio::log.blue "Home Assistant MQTT addon detected; auto-configuring BirdNET-Go"
bashio::log.blue "Broker: ${MQTT_BROKER}"
bashio::log.blue "User:   ${MQTT_USER}"
bashio::log.blue "(Set 'mqtt_disable: true' in addon options to opt out)"
bashio::log.green "---"

# $broker / $user / $pass / "birdnet" are jq/yq variables and literals,
# not shell expansions, so the single quotes are intentional.
# shellcheck disable=SC2016
yq -i -y \
    --arg broker "$MQTT_BROKER" \
    --arg user "$MQTT_USER" \
    --arg pass "$MQTT_PASS" \
    '.realtime.mqtt.enabled = true
     | .realtime.mqtt.broker = $broker
     | .realtime.mqtt.username = $user
     | .realtime.mqtt.password = $pass
     | .realtime.mqtt.topic //= "birdnet"' \
    "$CONFIG_LOCATION"
