#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2317
set -e

#################
# NGINX SETTING #
#################

exit 0

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

# Allows serving js
sed -i 's/<!-- %if-not-debug% -->/<!-- %if-not-debug%  /g' /app/sabnzbd/webui/index.html
sed -i 's/<!-- %end% -->/   %end% -->/g' /app/sabnzbd/webui/index.html
sed -i 's/<!-- %if-debug%/<!-- %if-debug% -->/g' /app/sabnzbd/webui/index.html
sed -i 's/	%end% -->/<!-- 	%end% -->/g' /app/sabnzbd/webui/index.html
