#!/usr/bin/bashio
# shellcheck shell=bash

########
# TEST #
########
if [ -f /config/tandoortest.sh ]; then
    echo "running test file"
    chmod +x /config/tandoortest.sh
    /./config/tandoortest.sh
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
