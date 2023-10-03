#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Launch App #
##############
echo " "
echo "Starting the app"
echo " "

python -u /app/gazpar2mqtt.py || echo "The app has crashed. Are you sure you entered the correct config options?"
