#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# SSL SETTING #
###############

if bashio::config.true 'ssl'; then
    bashio::log "Ssl is enabled using addon options, setting up nginx"
    bashio::config.require.ssl
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "/root/a tls /ssl/${certfile} /ssl/${keyfile}" /etc/caddy/Caddyfile
    sed -i "s|http://|https://|g" /etc/caddy/Caddyfile
fi

echo " "
