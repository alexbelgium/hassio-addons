#!/usr/bin/bashio
# shellcheck shell=bash

if [[ -n "${DISABLE_INGRESS}" ]]; then
    bashio::log.info "Ingress disabled"
    sed -i "/nginx/d" /etc/cont-init.d/99-run.sh
    exit 0
fi

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port

ingress_port="$(bashio::addon.ingress_port)"
ingress_interface="$(bashio::addon.ip_address)"
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
