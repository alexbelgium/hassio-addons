#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# nginx Path
NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf

# Copy template
cp /defaults/default.conf "${NGINX_CONFIG}"
# Remove ssl part
awk -v n=4 '/server/{n--}; n > 0' "${NGINX_CONFIG}" > tmpfile
mv tmpfile "${NGINX_CONFIG}"

# Remove ipv6
sed -i '/listen \[::\]/d' "${NGINX_CONFIG}"
# Add ingress parameters
sed -i "s|3000|$(bashio::addon.ingress_port)|g" "${NGINX_CONFIG}"
sed -i '/server {/a include /etc/nginx/includes/server_params.conf;' "${NGINX_CONFIG}"
sed -i '/server {/a include /etc/nginx/includes/proxy_params.conf;' "${NGINX_CONFIG}"

# Enable ingress
cp /etc/nginx/sites-available/ingress.conf /etc/nginx/sites-enabled
