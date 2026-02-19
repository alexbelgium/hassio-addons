#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

##################
# CONFIG SETTING #
##################

# Values
slug=seerr
CONFIG_LOCATION=/config/settings.json

if [ -f "$CONFIG_LOCATION" ]; then

    # Define UrlBase
    bashio::log.green "Setting UrlBase to $slug"
    node -e "
      var fs = require('fs');
      var s = JSON.parse(fs.readFileSync('$CONFIG_LOCATION', 'utf8'));
      if (!s.main) s.main = {};
      s.main.urlBase = '$slug';
      fs.writeFileSync('$CONFIG_LOCATION', JSON.stringify(s, null, 2));
    "

fi
