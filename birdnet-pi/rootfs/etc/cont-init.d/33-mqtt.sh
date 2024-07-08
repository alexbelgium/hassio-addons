#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::services.available 'mqtt'; then
    bashio::log.green "---"
    bashio::log.blue "MQTT addon is active on your system! Birdnet-pi is now automatically configured to send its ouptut to MQTT"
    bashio::log.blue "MQTT user : $(bashio::services "mqtt" "username")"
    bashio::log.blue "MQTT password : $(bashio::services "mqtt" "password")"
    bashio::log.blue "MQTT broker : tcp://$(bashio::services "mqtt" "host"):$(bashio::services "mqtt" "port")"
    bashio::log.green "---"

    # Apply MQTT settings
    sed -i "s|%%mqtt_server%%|$(bashio::services "mqtt" "host")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_port%%|$(bashio::services "mqtt" "port")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_user%%|$(bashio::services "mqtt" "username")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_pass%%|$(bashio::services "mqtt" "password")|g" /helpers/birdnet_to_mqtt.py

    # Copy script
    cp /helpers/birdnet_to_mqtt.py /usr/bin/birdnet_to_mqtt.py
    chmod 777 /usr/bin/birdnet_to_mqtt.py

    # Start python
    "$PYTHON_VIRTUAL_ENV" /usr/bin/birdnet_to_mqtt.py &>/proc/1/fd/1 & true

fi
