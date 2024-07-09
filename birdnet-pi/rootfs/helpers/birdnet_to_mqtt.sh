#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::services.available 'mqtt'; then
  echo "Starting service: mqtt publish"
  "$PYTHON_VIRTUAL_ENV" /usr/bin/birdnet_to_mqtt.py &>/proc/1/fd/1
fi
