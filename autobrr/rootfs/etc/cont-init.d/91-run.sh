#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

bashio::log.info "Starting nginx"
nginx & true

bashio::log.info "Starting app"
exec /usr/local/bin/autobrr --config /config/addons_config/autobrr
