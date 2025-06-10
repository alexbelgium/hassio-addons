#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# Start nginx #
###############

# Set UrlBase

bashio::log.info "Starting NGinx..."
nginx &
true

#############
# Start app #
#############

bashio::log.info "Starting app"
exec /usr/local/bin/autobrr --config /config/addons_config/autobrr
