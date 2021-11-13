#!/usr/bin/with-contenv bashio

###############
# SSL SETTING #
###############

if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    protocol=https
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    address=$(bashio::addon.ip_address)
    sed -i "s|%%interface%%|$address|g" /etc/nginx/templates/ssl.gtpl
    sed -i "s|%%certfile%%|/ssl/$certfile|g" /etc/nginx/templates/ssl.gtpl
    sed -i "s|%%certkey%%|/ssl/$keyfile|g" /etc/nginx/templates/ssl.gtpl
    mv /etc/nginx/templates/ssl.gtpl /etc/nginx/servers/ssl.conf
fi
