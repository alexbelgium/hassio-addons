#!/usr/bin/env bashio

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/gazpar2mqtt.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
