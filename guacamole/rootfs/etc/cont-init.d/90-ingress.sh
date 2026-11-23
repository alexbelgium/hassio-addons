#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_user
declare ingress_port

ingress_port=$(bashio::app.ingress_port)
ingress_interface=$(bashio::app.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

# The auth-header extension reads REMOTE_USER. Default to guacadmin, which is what
# this add-on has always sent; with login_with_ha_user, send the Home Assistant
# username that the Supervisor puts in X-Remote-User-Name on every ingress request.
ingress_user='guacadmin'
if bashio::config.true 'login_with_ha_user'; then
    # shellcheck disable=SC2016
    ingress_user='$http_x_remote_user_name'
    bashio::log.info "Ingress logs in with the Home Assistant username"
fi
sed -i "s|%%ingress_user%%|${ingress_user}|g" /etc/nginx/servers/ingress.conf

# auth-header trusts any REMOTE_USER header, and the published port reaches Tomcat without nginx
if [[ "$(bashio::config 'EXTENSIONS')" == *auth-header* ]] && bashio::var.has_value "$(bashio::app.port 8080)"; then
    bashio::log.warning "SECURITY RISK: the auth-header extension is enabled and port 8080 is published on host port $(bashio::app.port 8080)."
    bashio::log.warning "Anyone who can reach that port can send a REMOTE_USER header and log in as any Guacamole user, including guacadmin."
    bashio::log.warning "Disable the port in the add-on Network settings and use Ingress, or remove auth-header from EXTENSIONS."
fi
