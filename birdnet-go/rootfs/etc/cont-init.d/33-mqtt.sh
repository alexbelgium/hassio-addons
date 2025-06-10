#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Gives mqtt information

if bashio::services.available 'mqtt'; then
  bashio::log.green "---"
  bashio::log.yellow "MQTT addon is active on your system! Add the MQTT details below to the Birdnet-go config.yaml :"
  bashio::log.blue "MQTT user : $(bashio::services "mqtt" "username")"
  bashio::log.blue "MQTT password : $(bashio::services "mqtt" "password")"
  bashio::log.blue "MQTT broker : tcp://$(bashio::services "mqtt" "host"):$(bashio::services "mqtt" "port")"
  bashio::log.green "---"
fi
