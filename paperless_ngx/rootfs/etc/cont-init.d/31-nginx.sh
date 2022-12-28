#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.true 'ssl'; then

    # Adapt nginx template
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
    sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf

    # Check if files exist
    echo "... checking if referenced certificates exist"
    [ ! -f /ssl/"$certfile" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$certfile not found" && bashio::exit.nok
    [ ! -f /ssl/"$keyfile" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$keyfile not found" && bashio::exit.nok

    # Configure URL
    if bashio::config.has_value "PAPERLESS_URL"; then
        bashio::log.warning "Ssl enabled, your site will be available at $(bashio::config "PAPERLESS_URL"):$(bashio::addon.port 8443). Don't forget to enable the https alternative port in the addon options."
    else
        bashio::log.fatal "PAPERLESS_URL not set, you won't be able to access your site (CSRF error)"
    fi

else
    sed -i "s|default_server ssl|default_server|g" /etc/nginx/servers/direct.conf
    sed -i "/ssl/d" /etc/nginx/servers/direct.conf
fi
