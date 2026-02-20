#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Seerr Ingress    #
####################

bashio::log.info "Configuring Nginx for ingress..."

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)

# Update ingress.conf with actual values
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry_escaped%%|${ingress_entry//\//\\\/}|g" /etc/nginx/servers/ingress.conf

bashio::log.info "Nginx ingress configured on ${ingress_interface}:${ingress_port}"
