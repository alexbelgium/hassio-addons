#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare port
declare certfile
declare ingress_interface
declare ingress_user
declare ingress_port
declare keyfile

port=$(bashio::addon.port 80)
if bashio::var.has_value "${port}"; then
    bashio::config.require.ssl

    if bashio::config.true 'ssl'; then
        certfile=$(bashio::config 'certfile')
        keyfile=$(bashio::config 'keyfile')

        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
        sed -i "s/%%certfile%%/${certfile}/g" /etc/nginx/servers/direct.conf
        sed -i "s/%%keyfile%%/${keyfile}/g" /etc/nginx/servers/direct.conf

    else
        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
    fi
fi

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
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
if [[ "$(bashio::config 'EXTENSIONS')" == *auth-header* ]] && bashio::var.has_value "$(bashio::addon.port 8080)"; then
    bashio::log.warning "SECURITY RISK: the auth-header extension is enabled and port 8080 is published on host port $(bashio::addon.port 8080)."
    bashio::log.warning "Anyone who can reach that port can send a REMOTE_USER header and log in as any Guacamole user, including guacadmin."
    bashio::log.warning "Disable the port in the add-on Network settings and use Ingress, or remove auth-header from EXTENSIONS."
fi

# Implement SUBFOLDER value
if [ -f /etc/s6-overlay/s6-rc.d/svc-autostart/run ]; then sed -i "1a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/s6-overlay/s6-rc.d/svc-autostart/run; fi
if [ -f /etc/services.d/guacamole/run ]; then sed -i "2a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/services.d/guacamole/run; fi
if [ -f /etc/services.d/guacd/run ]; then sed -i "2a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/services.d/guacd/run; fi
