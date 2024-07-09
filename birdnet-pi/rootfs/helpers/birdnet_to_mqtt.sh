#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

echo "Starting service: mqtt automated publish"
"$PYTHON_VIRTUAL_ENV" /usr/bin/birdnet_to_mqtt.py &>/proc/1/fd/1
