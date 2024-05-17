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

# Create .htpasswd
echo "... setting up automatic identification"
export "$(grep "^CADDY_PWD" /config/birdnet.conf)"
htpasswd -b -c /home/pi/.htpasswd birdnet "$CADDY_PWD" &>/dev/null
chown 1000:1000 /home/pi/.htpasswd
#sed -i '/caddy_pwd,\$config/a exec("htpasswd -b -c /home/pi/.htpasswd birdnet \"$caddy_pwd\" &>/dev/null");' "$HOME"/BirdNET-Pi/scripts/advanced.php

echo " "
