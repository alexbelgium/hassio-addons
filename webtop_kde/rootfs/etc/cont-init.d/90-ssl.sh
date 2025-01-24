#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'use_own_certs'; then
    bashio::log.green "Using referenced ssl certificates. Please remember to open the ssl port in the addon options"
    CERTFILE=$(bashio::config 'certfile')
    KEYFILE=$(bashio::config 'keyfile')

    # Validate ssl
    bashio::config.require.ssl

    #Check if files exist
    echo "... checking if referenced files exist"
    [ ! -f /ssl/"$CERTFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$CERTFILE not found" && bashio::exit.nok
    [ ! -f /ssl/"$KEYFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$KEYFILE not found" && bashio::exit.nok


    # Add ssl file
    sed -i "s|/config/data/ssl/cert.pem|/ssl/$(bashio::config 'certfile')|g" "$NGINX_CONFIG"
    sed -i "s|/config/data/ssl/cert.key|/ssl/$(bashio::config 'keyfile')|g" "$NGINX_CONFIG"
fi
