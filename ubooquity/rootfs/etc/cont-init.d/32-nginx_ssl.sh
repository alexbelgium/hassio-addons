#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# SSL SETTING #
###############
declare port
declare certfile
#declare ingress_interface
#declare ingress_port
declare keyfile

# General values
port=2205
sed -i "s|%%port%%|$port|g" /etc/nginx/servers/ssl.conf
sed -i "s|%%interface%%|$(bashio::addon.ip_address)|g" /etc/nginx/servers/ssl.conf

# Ssl values
if bashio::config.true 'ssl'; then
  bashio::config.require.ssl
  certfile=$(bashio::config 'certfile')
  keyfile=$(bashio::config 'keyfile')
  sed -i "s|default_server|ssl|g" /etc/nginx/servers/ssl.conf
  sed -i "/proxy_params.conf/a ssl_certificate /ssl/$certfile;" /etc/nginx/servers/ssl.conf
  sed -i "/proxy_params.conf/a ssl_certificate_key /ssl/$keyfile;" /etc/nginx/servers/ssl.conf
  bashio::log.info "Ssl enabled, please use https for connection. UI is at https://YOURIP:$(bashio::addon.port 2205)/ubooquity ; admin is at https://YOURIP:$(bashio::addon.port 2206)/ubooquity/admin"
fi
