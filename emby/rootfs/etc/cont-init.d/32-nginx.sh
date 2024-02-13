#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

echo "Adapting for ingress"
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

# Allow uppercase url
echo "Allowing case sensitive url"
grep -rl toLowerCase /app/emby/system/dashboard-ui/app.js | xargs sed -i 's/toLowerCase()/toString()/g'
grep -rl toLowerCase /app/emby/system/dashboard-ui/network | xargs sed -i 's/toLowerCase()/toString()/g'
