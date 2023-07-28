#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046

#################
# NGINX SETTING #
#################

cp /etc/nginx/http.d/default.conf /etc/nginx/http.d/ingress.conf

ingress_port=$(bashio::addon.ingress_port)
#ingress_interface=$(bashio::addon.ip_address)
sed -i "s/3001/0001/g" /etc/nginx/http.d/ingress.conf
sed -i "s/3000/${ingress_port}/g" /etc/nginx/http.d/ingress.conf
#sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/sites-available/ingress.conf

# Implement SUBFOLDER value
sed -i "1a SUBFOLDER=$(bashio::addon.ingress_url)" $(find /etc/s6-overlay/s6-rc.d -name "run" -type f)
