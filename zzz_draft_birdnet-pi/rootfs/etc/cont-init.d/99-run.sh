#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
echo " "

########################
# CONFIGURE birdnet-pi #
########################

bashio::log.info "Starting app..."
COMMAND="$(bashio::config "COMMAND")"
# shellcheck disable=SC2086
/usr/bin/birdnet-pi $COMMAND & true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx

