#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

# Starting dbus
bashio::log.info "Starting system services..."
echo "... dbus"
service dbus start

# Starting php service
echo "... php"
until [[ -e /var/run/dbus/system_bus_socket ]]; do
    sleep 1s
done
systemctl start php*service

# Starting avahi service
echo "... avahi"
systemctl start avahi*service

# Restarting all services
bashio::log.info "Ensuring birdnet.conf is in /config ; please customize as needed"
if [ ! -f /config/birdnet.conf ]; then
  cp /etc/birdnet/birdnet.conf /config
fi

bashio::log.info "Starting BirdNET-Pi services"
chmod +x $HOME/BirdNET-Pi/scripts/restart_services
/.$HOME/BirdNET-Pi/scripts/restart_services &>/proc/1/fd/1

bashio::log.info "App is accessible from webui"