#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Remove not working elements
if bashio::config.true "NO_NOISE_MODEL"; then
  bashio::log.info "Activating the no_noise models as NO_NOISE_MODEL is true"
  sed -i "s|server.py --area|server.py --no_noise on --area|g" "$HOME"/BirdNET-Pi/scripts/batnet_analysis.sh
fi

# Add batnet service to monitoring service
sed -i "/sudo systemctl restart birdnet_analysis/a\sudo systemctl restart batnet_server" /custom-services.d/30-monitoring.sh
sed -i "s|spectrogram_viewer |spectrogram_viewer batnet_server |g" /custom-services.d/30-monitoring.sh

# Install gotty for amd64
if [ "$(uname -m)" == "x86_64" ]; then
  bashio::log.info "Install gotty for amd64"
  curl -L https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz | tar xz -C /tmp
  mv /tmp/gotty /usr/local/bin/gotty
  chmod +x /usr/local/bin/gotty
  sed -i "s| -P log| log|g" "$HOME"/BirdNET-Pi/templates/birdnet_log.service
fi

# Make sure bats model is on
echo 'sed -i "/BATS_ANALYSIS=/c\BATS_ANALYSIS=1" /config/birdnet.conf' >> /etc/cont-init.d/81-modifications.sh

#sed -i "1a exit 0" /etc/cont-init.d/33-mqtt.sh
#sed -i "1a sleep infinity" /custom-services.d/30-monitoring.sh
