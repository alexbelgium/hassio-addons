#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###############
# Start nginx #
###############

# Set UrlBase
#if ! grep -q "hassioautobrr" /config/addons_config/autobrr/config.toml; then
#  bashio::log.warning "BaseUrl not set properly, restarting"
#  sed -i "/baseUrl/d" /config/addons_config/autobrr/config.toml
#  sed -i "/# Base url/a baseUrl = \"\/hassioautobrr\/\"" /config/addons_config/autobrr/config.toml
#  bashio::addon.restart
#fi

#bashio::log.info "Starting NGinx..."
#nginx & true

#############
# Start app #
#############

bashio::log.info "Starting app"
exec /usr/local/bin/autobrr --config /config/addons_config/autobrr
