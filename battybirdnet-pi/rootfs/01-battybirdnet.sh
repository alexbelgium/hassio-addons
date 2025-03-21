#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Remove not working elements
sed -i "1a exit 0" /etc/cont-init.d/33-mqtt.sh
sed -i "1a sleep infinity" /custom-services.d/30-monitoring.sh

# Allow symlinks
for files in "$HOME"/BirdNET-Pi/scripts/*.sh; do
  sed -i "s|find |find -L|g" "$files"
  sed -i "s|find -L -L|find -L|g" "$files"
done
