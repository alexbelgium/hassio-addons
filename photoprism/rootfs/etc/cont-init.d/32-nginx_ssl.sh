#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# SSL SETTING #
###############
declare port
declare certfile
declare keyfile

# General values
port=2342
sed -i "s|%%port%%|$port|g" /etc/nginx/servers/ssl.conf
sed -i "s|%%interface%%|$(bashio::addon.ip_address)|g" /etc/nginx/servers/ssl.conf

# Ssl values
if bashio::config.true 'ssl'; then
    echo "Defining ssl configuration"
    bashio::config.require.ssl
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')

    #Check if files exist
    echo "... checking if referenced certificates exist"
    [ ! -f /ssl/"$certfile" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$certfile not found" && bashio::exit.nok
    [ ! -f /ssl/"$keyfile" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$keyfile not found" && bashio::exit.nok

    sed -i "s|default_server|ssl|g" /etc/nginx/servers/ssl.conf
    sed -i "/proxy_params.conf/a ssl_certificate /ssl/$certfile;" /etc/nginx/servers/ssl.conf
    sed -i "/proxy_params.conf/a ssl_certificate_key /ssl/$keyfile;" /etc/nginx/servers/ssl.conf
    bashio::log.info "Ssl enabled, please use https for connection. UI is at https://YOURIP:$(bashio::addon.port 2342)"
fi
