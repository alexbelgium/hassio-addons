#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# When the Home Assistant MQTT addon is active, optionally wire its
# credentials directly into BirdNET-Go's config.yaml. Upstream reads MQTT
# settings only from YAML (no env-var overrides exist), so this is the only
# way to auto-configure them. The behaviour is opt-in via the
# mqtt_auto_config addon option. When the option is off but Mosquitto is
# detected, we log a one-shot hint pointing users at the option.
#
# In addition to the broker credentials we enable BirdNET-Go's native Home
# Assistant MQTT auto-discovery (realtime.mqtt.homeassistant.*). This makes
# the detection sensors appear in Home Assistant automatically, so users no
# longer have to hand-write the MQTT sensor YAML from HAINTEGRATION.md.

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
    bashio::log.yellow "Home Assistant MQTT addon detected. Set 'mqtt_auto_config: true' in the addon options to wire it into BirdNET-Go automatically AND enable Home Assistant auto-discovery (sensors appear in HA with no manual YAML). Connection details:"
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
bashio::log.blue "Home Assistant auto-discovery: enabled (sensors appear in HA automatically)"
bashio::log.green "---"

# $broker / $user / $pass / "birdnet" are jq/yq variables and literals,
# not shell expansions, so the single quotes are intentional.
#
# Connection fields (enabled/broker/username/password) are force-set on every
# start so they track the HA MQTT addon's rotating credentials. Topic and the
# homeassistant.* discovery knobs use "//=" so they are only seeded when
# missing. retain is seeded via an explicit has() check rather than "//=",
# because jq treats a user-set "retain: false" as falsy and "//=" would wrongly
# flip it back to true; has() seeds the default only when the key is truly
# absent. Any value the user later changes in the BirdNET-Go UI or config.yaml
# therefore survives restarts. homeassistant.enabled is force-set to true
# because turning on discovery is the whole point of the auto-config option.
# shellcheck disable=SC2016
yq -i -y \
    --arg broker "$MQTT_BROKER" \
    --arg user "$MQTT_USER" \
    --arg pass "$MQTT_PASS" \
    '.realtime.mqtt.enabled = true
     | .realtime.mqtt.broker = $broker
     | .realtime.mqtt.username = $user
     | .realtime.mqtt.password = $pass
     | .realtime.mqtt.topic //= "birdnet"
     | (if (.realtime.mqtt | has("retain")) then . else .realtime.mqtt.retain = true end)
     | .realtime.mqtt.homeassistant.enabled = true
     | .realtime.mqtt.homeassistant.discovery_prefix //= "homeassistant"
     | .realtime.mqtt.homeassistant.device_name //= "BirdNET-Go"' \
    "$CONFIG_LOCATION"
