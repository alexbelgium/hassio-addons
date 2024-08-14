#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

common_steps () {

    # Copy script
    cp /helpers/birdnet_to_mqtt.py "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py
    chown pi:pi "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py
    chmod +x "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py

    # Add hooks
    sed -i "/load_global_model, run_analysis/a from utils.birdnet_to_mqtt import automatic_mqtt_publish" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i '/write_to_db(/a\            automatic_mqtt_publish(file, detections, os.path.basename(detection.file_name_extr))' "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py

}

if bashio::services.available 'mqtt' && ! bashio::config.true 'MQTT_DISABLED' ; then
    bashio::log.green "---"
    bashio::log.blue "MQTT addon is active on your system! Birdnet-pi is now automatically configured to send its ouptut to MQTT"
    bashio::log.blue "MQTT user : $(bashio::services "mqtt" "username")"
    bashio::log.blue "MQTT password : $(bashio::services "mqtt" "password")"
    bashio::log.blue "MQTT broker : tcp://$(bashio::services "mqtt" "host"):$(bashio::services "mqtt" "port")"
    bashio::log.green "---"
    bashio::log.blue "Data will be posted to the topic : 'birdnet'"
    bashio::log.blue "Json data : {'Date', 'Time', 'ScientificName', 'CommonName', 'Confidence', 'SpeciesCode', 'ClipName', 'url'}"
    bashio::log.blue "---"

    # Apply MQTT settings
    sed -i "s|%%mqtt_server%%|$(bashio::services "mqtt" "host")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_port%%|$(bashio::services "mqtt" "port")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_user%%|$(bashio::services "mqtt" "username")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_pass%%|$(bashio::services "mqtt" "password")|g" /helpers/birdnet_to_mqtt.py

    # Common steps
    common_steps

elif bashio::config.has_value "MQTT_HOST_manual" && bashio::config.has_value "MQTT_PORT_manual"; then
    bashio::log.green "---"
    bashio::log.blue "MQTT is manually configured in the addon options"
    bashio::log.blue "Birdnet-pi is now automatically configured to send its ouptut to MQTT"
    bashio::log.green "---"
    bashio::log.blue "Data will be posted to the topic : 'birdnet'"
    bashio::log.blue "Json data : {'Date', 'Time', 'ScientificName', 'CommonName', 'Confidence', 'SpeciesCode', 'ClipName', 'url'}"
    bashio::log.blue "---"

    # Apply MQTT settings
    sed -i "s|%%mqtt_server%%|$(bashio::config "MQTT_HOST_manual")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_port%%|$(bashio::config "MQTT_PORT_manual")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_user%%|$(bashio::config "MQTT_USER_manual")|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_pass%%|$(bashio::config "MQTT_PASSWORD_manual")|g" /helpers/birdnet_to_mqtt.py

    # Common steps
    common_steps

fi
