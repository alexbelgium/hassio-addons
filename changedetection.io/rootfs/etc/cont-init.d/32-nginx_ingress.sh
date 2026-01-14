#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port
declare ingress_entry

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)

sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "1" > /var/run/s6/container_environment/USE_X_SETTINGS
fi
