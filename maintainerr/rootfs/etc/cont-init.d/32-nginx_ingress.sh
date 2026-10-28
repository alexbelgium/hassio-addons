#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

bashio::log.info "Configuring NGinx for ingress..."

ingress_port=$(bashio::app.ingress_port)
ingress_interface=$(bashio::app.ip_address)
ingress_entry=$(bashio::app.ingress_entry)

sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

bashio::log.info "NGinx ingress configured on ${ingress_interface}:${ingress_port}"
