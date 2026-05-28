#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# When the Home Assistant MQTT addon is active, optionally wire its
# credentials directly into BirdNET-Go's config.yaml. Upstream reads MQTT
# settings only from YAML (no env-var overrides exist), so this is the only
# way to auto-configure them. The behaviour is opt-in via the
# mqtt_auto_config addon option. When the option is off but Mosquitto is
# detected, we log a one-shot hint pointing users at the option.

CONFIG_LOCATION="/config/config.yaml"

if ! bashio::services.available 'mqtt'; then
    exit 0
fi

MQTT_HOST="$(bashio::services 'mqtt' 'host')"
MQTT_PORT="$(bashio::services 'mqtt' 'port')"
MQTT_USER="$(bashio::services 'mqtt' 'username')"
MQTT_PASS="$(bashio::services 'mqtt' 'password')"
MQTT_BROKER="tcp://${MQTT_HOST}:${MQTT_PORT}"

if ! bashio::config.true 'mqtt_auto_config'; then
    bashio::log.green "---"
    bashio::log.yellow "Home Assistant MQTT addon detected. Set 'mqtt_auto_config: true' in the addon options to wire it into BirdNET-Go automatically. Connection details:"
    bashio::log.blue "MQTT user    : ${MQTT_USER}"
    bashio::log.blue "MQTT password: ${MQTT_PASS}"
    bashio::log.blue "MQTT broker  : ${MQTT_BROKER}"
    bashio::log.green "---"
    exit 0
fi

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "Skipping MQTT auto-configuration: $CONFIG_LOCATION not found"
    exit 0
fi

bashio::log.green "---"
bashio::log.blue "mqtt_auto_config enabled; writing Home Assistant MQTT credentials into BirdNET-Go config"
bashio::log.blue "Broker: ${MQTT_BROKER}"
bashio::log.blue "User:   ${MQTT_USER}"
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
