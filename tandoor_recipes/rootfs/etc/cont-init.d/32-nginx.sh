#!/usr/bin/bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'ssl'; then

    # Validate ssl
    bashio::config.require.ssl

    # Adapt nginx template
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "s|%%certfile%%|${certfile}|g" /etc/nginx/servers/ssl.conf
    sed -i "s|%%keyfile%%|${keyfile}|g" /etc/nginx/servers/ssl.conf
    sed -i "s|8080;|8080 ssl;|g" /etc/nginx/servers/ssl.conf

else

    sed -i "/ssl/d" /etc/nginx/servers/ssl.conf

fi
