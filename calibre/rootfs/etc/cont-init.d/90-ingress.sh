#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# nginx Path
NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf
SUBFOLDER="$(bashio::addon.ingress_entry)"

# Copy template
cp /defaults/default.conf "${NGINX_CONFIG}"

# Keep only the first (non-SSL) server block
awk -v n=4 '/server/{n--}; n > 0' "${NGINX_CONFIG}" > tmpfile
mv tmpfile "${NGINX_CONFIG}"

# Remove ipv6
sed -i '/listen \[::\]/d' "${NGINX_CONFIG}"

# Use ingress port
sed -i "s|3000|$(bashio::addon.ingress_port)|g" "${NGINX_CONFIG}"

# Put /devmode under the ingress path and fix SUBFOLDER-prefixed paths
sed -i 's|location /devmode|location SUBFOLDER/devmode|g' "${NGINX_CONFIG}"
sed -i 's|SUBFOLDER\([A-Za-z]\)|SUBFOLDER/\1|g' "${NGINX_CONFIG}"
sed -i 's|SUBFOLDER50x\.html|SUBFOLDER/50x.html|g' "${NGINX_CONFIG}"
sed -i "s|SUBFOLDER|${SUBFOLDER%/}|g" "${NGINX_CONFIG}"

# Replace placeholders
sed -i "s|CWS|8082|g" "${NGINX_CONFIG}"
sed -i "s|REPLACE_HOME|${HOME:-/root}|g" "${NGINX_CONFIG}"

# Enable ingress
cp /etc/nginx/sites-available/ingress.conf /etc/nginx/sites-enabled
