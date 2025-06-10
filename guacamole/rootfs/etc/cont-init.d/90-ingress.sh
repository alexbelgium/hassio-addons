#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare port
declare certfile
declare ingress_interface
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

# Implement SUBFOLDER value
if [ -f /etc/s6-overlay/s6-rc.d/svc-autostart/run ]; then sed -i "1a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/s6-overlay/s6-rc.d/svc-autostart/run; fi
if [ -f /etc/services.d/guacamole/run ]; then sed -i "2a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/services.d/guacamole/run; fi
if [ -f /etc/services.d/guacd/run ]; then sed -i "2a SUBFOLDER=$(bashio::addon.ingress_url)" /etc/services.d/guacd/run; fi
