#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
bashio::log.blue "Listing available listening devices"
arecord -l
echo " "

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
/usr/bin/birdnet-go realtime
