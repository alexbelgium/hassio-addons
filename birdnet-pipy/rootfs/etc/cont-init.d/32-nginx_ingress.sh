#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

declare ingress_interface
declare ingress_port

ingress_port="$(bashio::addon.ingress_port)"
ingress_interface="$(bashio::addon.ip_address)"
ingress_entry="$(bashio::addon.ingress_entry)"
ingress_entry_modified="$(echo "$ingress_entry" | sed 's/[@_!#$%^&*()<>?/\|}{~:]//g')"

sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s#%%ingress_entry%%#${ingress_entry}#g" /etc/nginx/servers/ingress.conf
sed -i "s#%%ingress_entry_modified%%#/${ingress_entry_modified}#g" /etc/nginx/servers/ingress.conf
sed -i "s#%%ingress_entry%%#${ingress_entry}#g" /etc/nginx/servers/nginx.conf
sed -i "s#%%ingress_entry_modified%%#/${ingress_entry_modified}#g" /etc/nginx/servers/nginx.conf

# Set DNS resolver for internal requests
sed -i "s/%%dns_host%%/127.0.0.11/g" /etc/nginx/includes/resolver.conf
