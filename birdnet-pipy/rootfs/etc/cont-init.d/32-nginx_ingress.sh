#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

if ! bashio::supervisor.ping 2>/dev/null; then
    bashio::log.warning "Supervisor unavailable; skipping ingress configuration."
    exit 0
fi

ingress_port="$(bashio::addon.ingress_port || true)"
ingress_interface="$(bashio::addon.ip_address || true)"
ingress_entry="$(bashio::addon.ingress_entry || true)"
ingress_entry_modified="$(echo "$ingress_entry" | sed 's/[@_!#$%^&*()<>?/\|}{~:]//g')"

sed -i \
    -e "s|proxy_pass http://api|proxy_pass http://127.0.0.1|g" \
    -e "s|proxy_pass http://icecast|proxy_pass http://127.0.0.1|g" \
    /etc/nginx/servers/nginx.conf

cp /etc/nginx/servers/nginx.conf /etc/nginx/servers/ingress.conf
sed -i \
    -e "s|listen 80;|listen ${ingress_interface}:${ingress_port} default_server;|g" \
    -e "/index index.html;/a\\    include /etc/nginx/includes/ingress_params.conf;" \
    /etc/nginx/servers/ingress.conf

sed -i "s#%%ingress_entry%%#${ingress_entry}#g" /etc/nginx/includes/ingress_params.conf
sed -i "s#%%ingress_entry_modified%%#/${ingress_entry_modified}#g" /etc/nginx/includes/ingress_params.conf

# Set DNS resolver for internal requests
sed -i "s/%%dns_host%%/127.0.0.11/g" /etc/nginx/includes/resolver.conf
