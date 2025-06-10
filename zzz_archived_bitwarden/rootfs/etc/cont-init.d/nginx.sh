#!/command/with-contenv bashio
# shellcheck shell=bash
set -e
# ==============================================================================
# Home Assistant Community Add-on: Bitwarden
# This file configures nginx
# ==============================================================================
declare certfile
declare keyfile
declare max_body_size

bashio::config.require.ssl

if bashio::config.true 'ssl'; then
  certfile=$(bashio::config 'certfile')
  keyfile=$(bashio::config 'keyfile')

  mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
  sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
  sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf
else
  mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
fi

max_body_size="10M"
# Increase body size to match config
if bashio::config.has_value 'request_size_limit'; then
  max_body_size=$(bashio::config 'request_size_limit')
fi
sed -i "s/%%max_body_size%%/${max_body_size}/g" \
  /etc/nginx/includes/server_params.conf
