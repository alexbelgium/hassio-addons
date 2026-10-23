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

sed -i "s/%%port%%/${ingress_port:-8099}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface:-0.0.0.0}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry:-/ingress}|g" /etc/nginx/servers/ingress.conf
