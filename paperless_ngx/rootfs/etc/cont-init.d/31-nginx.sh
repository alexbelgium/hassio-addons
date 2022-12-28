#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.true 'ssl'; then
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
    sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf
else
    sed -i "s|default_server ssl|default_server|g" /etc/nginx/servers/direct.conf
    sed -i "/ssl/d" /etc/nginx/servers/direct.conf
fi
