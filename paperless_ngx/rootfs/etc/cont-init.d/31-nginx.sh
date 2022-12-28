#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.true 'ssl'; then
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
    sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf

    if bashio::config.has_value "PAPERLESS_URL"; then
        bashio::log.warning "Ssl enabled, your site will be available at $(bashio::config "PAPERLESS_URL"):$(bashio::addon.port 8000)"
    else
        bashio::log.fatal "PAPERLESS_URL not set, you won't be able to access your site (CSRF error)"
    fi

else
    sed -i "s|default_server ssl|default_server|g" /etc/nginx/servers/direct.conf
    sed -i "/ssl/d" /etc/nginx/servers/direct.conf
fi
