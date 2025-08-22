#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# nginx Path
NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf
SUBFOLDER="$(bashio::addon.ingress_entry)"

# Copy template
cp /defaults/default.conf "${NGINX_CONFIG}"
# Remove ssl part
awk -v n=4 '/server/{n--}; n > 0' "${NGINX_CONFIG}" > tmpfile
mv tmpfile "${NGINX_CONFIG}"

# Remove ipv6
sed -i '/listen \[::\]/d' "${NGINX_CONFIG}"
# Add ingress parameters
sed -i "s|CWS|$(bashio::addon.ingress_port)|g" "${NGINX_CONFIG}"
sed -i 's|proxy_pass http://|proxy_pass https://|g' "${NGINX_CONFIG}"
sed -i '/proxy_pass/a proxy_ssl_verify off;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a proxy_set_header Accept-Encoding "";' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_once off;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_types *;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter "vnc/index.html?autoconnect" "vnc/index.html?path=%%path%%/websockify?autoconnect";' "${NGINX_CONFIG}"
sed -i "s|%%path%%|${SUBFOLDER:1}|g" "${NGINX_CONFIG}"

# Correct image
sed -i "s|SUBFOLDERwebsockify|/websockify|g" "${NGINX_CONFIG}"

# Enable ingress
cp /etc/nginx/sites-available/ingress.conf /etc/nginx/sites-enabled
