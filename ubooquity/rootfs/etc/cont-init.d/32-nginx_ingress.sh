#!/usr/bin/with-contenv bashio

###################
# INGRESS SETTING #
###################
declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

# General values
port=$(bashio::addon.ingress_port)
sed -i "s|%%port%%|$port|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|$(bashio::addon.ip_address)|g" /etc/nginx/servers/ingress.conf
