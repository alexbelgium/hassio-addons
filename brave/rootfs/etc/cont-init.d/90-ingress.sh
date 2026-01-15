#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

declare ingress_user
declare ingress_interface
declare ingress_port

ingress_user='admin'
if bashio::config.has_value 'ingress_user'; then
    ingress_user=$(bashio::config 'ingress_user')
fi

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)

sed -i "s/%%ingress_user%%/${ingress_user}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%UIPATH%%|$(bashio::addon.ingress_entry)|g" /etc/nginx/servers/ingress.conf

SUBFOLDER="$(bashio::addon.ingress_entry)"
if [[ -n "${SUBFOLDER}" && "${SUBFOLDER}" != "/" ]]; then
    [[ "${SUBFOLDER}" == */ ]] || SUBFOLDER="${SUBFOLDER}/"
fi

if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "${SUBFOLDER}" > /var/run/s6/container_environment/SUBFOLDER
fi
