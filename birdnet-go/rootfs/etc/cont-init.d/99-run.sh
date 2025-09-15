#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
# shellcheck disable=SC2086
/usr/bin/entrypoint.sh birdnet-go realtime &
true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx
