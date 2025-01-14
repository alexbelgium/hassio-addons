#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port
declare ingress_entry

echo "Adapting for ingress"
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/http.d/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/http.d/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/http.d/ingress.conf
