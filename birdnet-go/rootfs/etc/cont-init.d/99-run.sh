#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
echo " "

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
COMMAND="$(bashio::config "COMMAND")"
# shellcheck disable=SC2086
mkdir -p /root/.config/birdnet-go
cd /root/.config/birdnet-go
pwd

/usr/bin/birdnet-go $COMMAND & true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx

