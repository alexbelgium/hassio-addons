#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

# Correcting systemctl
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl
chmod a+x /bin/systemctl

# Starting dbus
bashio::log.info "Starting system services..."
echo "... dbus"
service dbus start

# Restarting all services
bashio::log.info "Ensuring birdnet.conf is in /config ; please customize as needed"
if [ ! -f /config/birdnet.conf ]; then
  cp /etc/birdnet/birdnet.conf /config
fi

bashio::log.info "Starting BirdNET-Pi services"
chmod +x $HOME/BirdNET-Pi/scripts/restart_services.sh
/.$HOME/BirdNET-Pi/scripts/restart_services.sh &>/proc/1/fd/1

bashio::log.info "App is accessible from webui"