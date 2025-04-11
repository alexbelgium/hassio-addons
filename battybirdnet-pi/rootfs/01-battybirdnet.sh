#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Remove not working elements
if bashio::config.true "NO_NOISE_MODEL"; then
  bashio::log.info "Activating the no_noise models as NO_NOISE_MODEL is true"
  sed -i "s|server.py --area|server.py --no_noise on --area|g" "$HOME"/BirdNET-Pi/scripts/batnet_analysis.sh
fi

#sed -i "1a exit 0" /etc/cont-init.d/33-mqtt.sh
#sed -i "1a sleep infinity" /custom-services.d/30-monitoring.sh
