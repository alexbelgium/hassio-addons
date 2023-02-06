#!/usr/bin/env bashio
# shellcheck shell=bash

###################
# Disable Ingress #
###################

if bashio::config.true "ingress_disabled"; then
    bashio::log.warning "Ingress is disabled. You'll need to connect using ip:port"
    rm /etc/nginx/servers/ingress.conf
    rm -r /etc/services.d/nginx
    # Set base url
    CONFIG_LOCATION=/config/addons_config/radarr/config.xml
    if bashio::config.has_value 'CONFIG_LOCATION'; then
      CONFIG_LOCATION="$(bashio::config 'CONFIG_LOCATION')"
      # Modify if it is a base directory
      if [[ "$CONFIG_LOCATION" == *.* ]]; then CONFIG_LOCATION="$(dirname $CONFIG_LOCATION)"; fi
      CONFIG_LOCATION="$CONFIG_LOCATION"/config.xml
      if grep -q "UrlBase" "$CONFIG_LOCATION" || true; then
        bashio::log.warning "BaseUrl removed, restarting"
        sed -i "/UrlBase/d" "$CONFIG_LOCATION"
        bashio::addon.restart
      fi      
    fi    
fi
