#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155
set -e

#####################
# Autodiscover mqtt #
#####################

if bashio::config.true 'mqtt_autodiscover'; then
	bashio::log.info "mqtt_autodiscover is defined in options, attempting autodiscovery..."
	# Check if available
	if ! bashio::services.available "mqtt"; then bashio::exit.nok "No internal MQTT service found. Please install Mosquitto broker"; fi
	# Get variables
	bashio::log.info "... MQTT service found, fetching server detail (you can enter those manually in your config file) ..."
	export MQTT_HOST=$(bashio::services mqtt "host") || bashio::log.error "can't fetch bashio::services mqtt 'host'"
	export MQTT_PORT=$(bashio::services mqtt "port") || bashio::log.error "can't fetch bashio::services mqtt 'port'"
	export MQTT_SSL=$(bashio::services mqtt "ssl") || bashio::log.error "can't fetch bashio::services mqtt 'ssl'"
	export MQTT_USERNAME=$(bashio::services mqtt "username") || bashio::log.error "can't fetch bashio::services mqtt 'username'"
	export MQTT_PASSWORD=$(bashio::services mqtt "password") || bashio::log.error "can't fetch bashio::services mqtt 'password'"

	# Export variables
	for variables in "MQTT_HOST=$MQTT_HOST" "MQTT_PORT=$MQTT_PORT" "MQTT_SSL=$MQTT_SSL" "MQTT_USERNAME=$MQTT_USERNAME" "MQTT_PASSWORD=$MQTT_PASSWORD"; do
		sed -i "1a export $variables" /etc/cont-init.d/*/*run* 2>/dev/null || true
		# Log
		bashio::log.blue "$variables"
	done
fi
