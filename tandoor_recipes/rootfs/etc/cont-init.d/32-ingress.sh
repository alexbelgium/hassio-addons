#!/usr/bin/bashio
# shellcheck shell=bash

########
# TEST #
########
if [ -f /config/tandooringress.conf ]; then
    echo "running test file"
    rm /etc/nginx/servers/ingress.conf
    cp /config/tandooringress.conf /etc/nginx/servers/ingress.conf
    chmod 775 /etc/nginx/servers/ingress.conf
fi

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port

ingress_port="$(bashio::addon.ingress_port)"
ingress_interface="$(bashio::addon.ip_address)"
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
