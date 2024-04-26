#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

# Starting dbus
echo "Starting service: dbus"
service dbus start

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
echo " "

########################
# CONFIGURE birdnet-pi #
########################

bashio::log.info "Starting app..."

if [ ! -f /config/birdnet.conf ]; then
  cp /etc/birdnet/birdnet.conf /config
fi
