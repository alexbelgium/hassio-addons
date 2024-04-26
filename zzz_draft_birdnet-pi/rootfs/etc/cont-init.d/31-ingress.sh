#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

bashio::log.info "Setting up ingress"

echo "... adding new instructions"
cat /Caddyfile >> /etc/caddy/Caddyfile
rm /Caddyfile

echo "... customizing"
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/caddy/Caddyfile
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/caddy/Caddyfile
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/caddy/Caddyfile