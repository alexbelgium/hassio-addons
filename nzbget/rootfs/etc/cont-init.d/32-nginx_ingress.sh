#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

# Allows serving js
sed -i 's/<!-- %if-not-debug% -->/<!-- %if-not-debug%  /g' /app/nzbget/webui/index.html
sed -i 's/<!-- %end% -->/   %end% -->/g' /app/nzbget/webui/index.html
sed -i 's/<!-- %if-debug%/<!-- %if-debug% -->/g' /app/nzbget/webui/index.html
sed -i 's/	%end% -->/<!-- 	%end% -->/g' /app/nzbget/webui/index.html
