#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

ingress_port="$(bashio::addon.ingress_port)"
ingress_interface="$(bashio::addon.ip_address)"
ingress_entry="$(bashio::addon.ingress_entry)"

sed -i \
    -e "s|proxy_pass http://api|proxy_pass http://127.0.0.1|g" \
    -e "s|proxy_pass http://icecast|proxy_pass http://127.0.0.1|g" \
    /etc/nginx/servers/nginx.conf

cp /etc/nginx/servers/nginx.conf /etc/nginx/servers/ingress.conf
sed -i \
    -e "s|listen 80;|listen ${ingress_interface}:${ingress_port} default_server;|g" \
    -e "/index index.html;/a\\    include /etc/nginx/includes/ingress_params.conf;" \
    -e 's|^[[:space:]]*add_header X|#&|g' \
    /etc/nginx/servers/ingress.conf

sed -i "s#%%ingress_entry%%#${ingress_entry}#g" /etc/nginx/includes/ingress_params.conf

# Set DNS resolver for internal requests
sed -i "s/%%dns_host%%/127.0.0.11/g" /etc/nginx/includes/resolver.conf
