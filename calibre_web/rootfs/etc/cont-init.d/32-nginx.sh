#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
#declare port
#declare certfile
declare ingress_user
declare ingress_interface
declare ingress_port
#declare keyfile

#port=$(bashio::addon.port 80)
#if bashio::var.has_value "${port}"; then
#    bashio::config.require.ssl
#
#    if bashio::config.true 'ssl'; then
#        certfile=$(bashio::config 'certfile')
#        keyfile=$(bashio::config 'keyfile')
#
#        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
#        sed -i "s/%%certfile%%/${certfile}/g" /etc/nginx/servers/direct.conf
#        sed -i "s/%%keyfile%%/${keyfile}/g" /etc/nginx/servers/direct.conf
#
#    else
#        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
#    fi
#fi

## Force scheme
#if bashio::config.true 'force_scheme_https'; then
#    # shellcheck disable=SC2016
#    sed -i 's|$scheme|https|g' /etc/nginx/servers/ingress.conf
#fi

## Force external port
#if bashio::config.has_value 'force_external_port'; then
#    sed -i "s|%%haport%%|$(bashio::config 'force_external_port')|g" /etc/nginx/servers/ingress.conf
#fi

ingress_user='admin'
if bashio::config.has_value 'ingress_user'; then
	ingress_user=$(bashio::config 'ingress_user')
fi

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
#ha_port=$(bashio::core.port)

sed -i "s/%%ingress_user%%/${ingress_user}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
#sed -i "s/%%haport%%/${ha_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%UIPATH%%|$(bashio::addon.ingress_entry)|g" /etc/nginx/servers/ingress.conf
