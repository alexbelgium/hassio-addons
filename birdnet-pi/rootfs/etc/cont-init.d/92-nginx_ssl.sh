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
    sed -i "2a\    tls /ssl/${certfile} /ssl/${keyfile}" /etc/caddy/Caddyfile
    sed -i "s|http://:8081|https://:8081|g" /etc/caddy/Caddyfile
    sed -i "s|http://:8081|https://:8081|g" "$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh
fi

echo " "
