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

# Symlink files
########################
# Create configuration file
if [ ! -f /config/birdnet.conf ]; then cp /etc/birdnet/birdnet.conf /config; fi
if [ -f "$HOME"/BirdNET-Pi/birdnet.conf ]; then rm "$HOME"/BirdNET-Pi/birdnet.conf; fi
chown 1000:1000 /config/birdnet.conf
ln -s /config/birdnet.conf "$HOME"/BirdNET-Pi/
chown 1000:1000 -h "$HOME"/BirdNET-Pi/birdnet.conf

# Create sqlite database
if [ ! -f /config/birds.db ]; then touch /config/birds.db; fi
if [ -f "$HOME"/BirdNET-Pi/scripts/birds.db ]; then rm "$HOME"/BirdNET-Pi/scripts/birds.db; fi
chown 1000:1000 /config/birds.db
ln -s /config/birds.db "$HOME"/BirdNET-Pi/scripts/
chown 1000:1000 -h "$HOME"/BirdNET-Pi/scripts/birds.db

bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
/."$HOME"/BirdNET-Pi/scripts/restart_services.sh &>/proc/1/fd/1

bashio::log.info "App is accessible from webui"
