#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

nginx & bashio::log.info "Starting nginx"



bashio::log.info "Starting app"
exec /usr/local/bin/autobrr --config /config/addons_config/autobrr
