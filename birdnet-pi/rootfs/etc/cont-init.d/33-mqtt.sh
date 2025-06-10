#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
  mkdir -p /etc/scripts-init
  sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
  sed -i "/ rm/d" /ha_entrypoint.sh
  cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

############
# SET MQTT #
############

# Function to perform common setup steps
common_steps() {
  # Attempt to connect to the MQTT broker
  TOPIC="birdnet"
  if mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$TOPIC" -m "test" -u "$MQTT_USER" -P "$MQTT_PASS" -q 1 -d --will-topic "$TOPIC" --will-payload "Disconnected" --will-qos 1 --will-retain >/dev/null 2>&1; then
    # Adapt script with MQTT settings
    sed -i "s|%%mqtt_server%%|$MQTT_HOST|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|\"%%mqtt_port%%\"|$MQTT_PORT|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_user%%|$MQTT_USER|g" /helpers/birdnet_to_mqtt.py
    sed -i "s|%%mqtt_pass%%|$MQTT_PASS|g" /helpers/birdnet_to_mqtt.py

    # Copy script to the appropriate directory
    cp /helpers/birdnet_to_mqtt.py "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py
    chown pi:pi "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py
    chmod +x "$HOME"/BirdNET-Pi/scripts/utils/birdnet_to_mqtt.py

    # Add hooks to the main analysis script
    sed -i "/load_global_model, run_analysis/a from utils.birdnet_to_mqtt import automatic_mqtt_publish" "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
    sed -i '/write_to_db(/a\                automatic_mqtt_publish(file, detection, os.path.basename(detection.file_name_extr))' "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py
  else
    bashio::log.fatal "MQTT connection failed, it will not be configured"
  fi
}

# Check if MQTT service is available and not disabled
if [[ -f "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py ]] && bashio::services.available 'mqtt' && ! bashio::config.true 'MQTT_DISABLED'; then
  bashio::log.green "---"
  bashio::log.blue "MQTT addon is active on your system! Birdnet-pi is now automatically configured to send its output to MQTT"
  bashio::log.blue "MQTT user : $(bashio::services "mqtt" "username")"
  bashio::log.blue "MQTT password : $(bashio::services "mqtt" "password")"
  bashio::log.blue "MQTT broker : tcp://$(bashio::services "mqtt" "host"):$(bashio::services "mqtt" "port")"
  bashio::log.green "---"
  bashio::log.blue "Data will be posted to the topic : 'birdnet'"
  bashio::log.blue "Json data : {'Date', 'Time', 'ScientificName', 'CommonName', 'Confidence', 'SpeciesCode', 'ClipName', 'url'}"
  bashio::log.blue "---"

  # Apply MQTT settings
  MQTT_HOST="$(bashio::services "mqtt" "host")"
  MQTT_PORT="$(bashio::services "mqtt" "port")"
  MQTT_USER="$(bashio::services "mqtt" "username")"
  MQTT_PASS="$(bashio::services "mqtt" "password")"

  # Perform common setup steps
  common_steps

# Check if manual MQTT configuration is provided
elif [[ -f "$HOME"/BirdNET-Pi/scripts/birdnet_analysis.py ]] && bashio::config.has_value "MQTT_HOST_manual" && bashio::config.has_value "MQTT_PORT_manual"; then
  bashio::log.green "---"
  bashio::log.blue "MQTT is manually configured in the addon options"
  bashio::log.blue "Birdnet-pi is now automatically configured to send its output to MQTT"
  bashio::log.green "---"
  bashio::log.blue "Data will be posted to the topic : 'birdnet'"
  bashio::log.blue "Json data : {'Date', 'Time', 'ScientificName', 'CommonName', 'Confidence', 'SpeciesCode', 'ClipName', 'url'}"
  bashio::log.blue "---"

  # Apply manual MQTT settings
  MQTT_HOST="$(bashio::config "MQTT_HOST_manual")"
  MQTT_PORT="$(bashio::config "MQTT_PORT_manual")"
  MQTT_USER="$(bashio::config "MQTT_USER_manual")"
  MQTT_PASS="$(bashio::config "MQTT_PASSWORD_manual")"

  # Perform common setup steps
  common_steps

fi
