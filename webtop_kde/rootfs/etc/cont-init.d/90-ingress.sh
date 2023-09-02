#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# nginx Path
NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf

# user passed env vars
CPORT="${CUSTOM_PORT:-3000}"
CHPORT="${CUSTOM_HTTPS_PORT:-3001}"
CUSER="${CUSTOM_USER:-abc}"

# Add ingress parameters
cp /defaults/default.conf ${NGINX_CONFIG}
sed -i '/listen \[::\]/d' ${NGINX_CONFIG}
sed -i '/server {/a include /etc/nginx/includes/server_params.conf;' ${NGINX_CONFIG}
sed -i '/server {/a include /etc/nginx/includes/proxy_params.conf;' ${NGINX_CONFIG}
sed -i "s|3000|$(bashio::addon.ingress_port)|g" ${NGINX_CONFIG}

# Implement SUBFOLDER value
#sed -i "1a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/s6-overlay/s6-rc.d/svc-autostart/run || true

# Enable ingress
cp /etc/nginx/sites-available/ingress.conf /etc/nginx/sites-enabled
