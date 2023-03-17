#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###############
# Start nginx #
###############
# Set variables
slug=autobrr
port=7474
CONFIG_LOCATION=/config/addons_config/"$slug"/config.toml

# Set UrlBase
if ! grep -q "<UrlBase>/hassioautobrr</UrlBase>" "$CONFIG_LOCATION" && ! bashio::config.true "ingress_disabled"; then
  bashio::log.warning "BaseUrl not set properly, restarting"
  sed -i "/baseUrl/d" /config/addons_config/autobrr/config.toml
  sed -i "/# Base url/a baseUrl = \"/hassioautobrr/\"" /config/addons_config/autobrr/config.toml
  bashio::addon.restart
fi

bashio::log.info "Starting NGinx..."
exec nginx

#############
# Start app #
#############

bashio::log.info "Starting app"
exec /usr/local/bin/autobrr --config /config/addons_config/autobrr
