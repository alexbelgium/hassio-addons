#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'use_own_certs'; then
  bashio::log.green "Using referenced ssl certificates to connect with https. Please remember to open the ssl port in the addon options"
  CERTFILE="$(bashio::config 'certfile')"
  KEYFILE="$(bashio::config 'keyfile')"
  NGINX_CONFIG="/defaults/default.conf"

  #Check if files exist
  echo "... checking if referenced files exist"
  if [ -f /ssl/"$CERTFILE" ] && [ -f /ssl/"$KEYFILE" ]; then
    # Add ssl file
    sed -i "s|/config/data/ssl/cert.pem|/ssl/$CERTFILE|g" "$NGINX_CONFIG"
    sed -i "s|/config/data/ssl/cert.key|/ssl/$KEYFILE|g" "$NGINX_CONFIG"
    echo "... done"
  else
    bashio::log.warning "...  certificate /ssl/$CERTFILE and /ssl/$KEYFILE and not found, using self-generated certificates"
  fi

fi
