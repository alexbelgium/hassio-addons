#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# nginx Path
NGINX_CONFIG=/etc/nginx/http.d/ingress.conf

# user passed env vars
CPORT="${CUSTOM_PORT:-3000}"
CHPORT="${CUSTOM_HTTPS_PORT:-3001}"
CUSER="${CUSTOM_USER:-abc}"

# create self signed cert
if [ ! -f "/config/ssl/cert.pem" ]; then
  mkdir -p /config/ssl
  openssl req -new -x509 \
    -days 3650 -nodes \
    -out /config/ssl/cert.pem \
    -keyout /config/ssl/cert.key \
    -subj "/C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*"
  chmod 600 /config/ssl/cert.key
  chown -R abc:abc /config/ssl
fi

# modify nginx config
cp /defaults/default.conf ${NGINX_CONFIG}
sed -i "s/3000/$CPORT/g" ${NGINX_CONFIG}
sed -i "s/3001/$CHPORT/g" ${NGINX_CONFIG}
if [ ! -z ${DISABLE_IPV6+x} ]; then
  sed -i '/listen \[::\]/d' ${NGINX_CONFIG}
fi
if [ ! -z ${PASSWORD+x} ]; then
  printf "${CUSER}:$(openssl passwd -apr1 ${PASSWORD})\n" > /etc/nginx/.htpasswd
  sed -i 's/#//g' ${NGINX_CONFIG}
fi

# Add ingress parameters
sed -i '/server {/a include /etc/nginx/includes/server_params.conf;' ${NGINX_CONFIG}
sed -i '/server {/a include /etc/nginx/includes/proxy_params.conf;;' ${NGINX_CONFIG}
sed -i 's|3000 default_server;|%%interface%%:%%port%% default_server;|g' ${NGINX_CONFIG}

# Implement SUBFOLDER value
sed -i "1a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/s6-overlay/s6-rc.d/svc-autostart/run || true
