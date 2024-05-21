#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port
declare ingress_entry

# Variables
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)

# Quits if ingress not active
if [ -z "$ingress_entry" ]; then exit 0; fi

echo " "
bashio::log.info "Adapting for ingress"
echo "... setting up nginx"
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

echo "... ensuring restricted area access"
echo "${ingress_entry}" > /ingress_url
sed -i "/function is_authenticated/a if (strpos(\$_SERVER['HTTP_REFERER'], '/api/hassio_ingress') !== false && strpos(\$_SERVER['HTTP_REFERER'], trim(file_get_contents('/ingress_url'))) !== false) { \$ret = true; return \$ret; }" "$HOME"/BirdNET-Pi/scripts/common.php

echo "... adapt Caddyfile for ingress"
chmod +x /helpers/caddy_ingress.sh
sed -i "/sudo caddy fmt --overwrite/i /./helpers/caddy_ingress.sh" /etc/caddy/Caddyfile "$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh

echo " "
