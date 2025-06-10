#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# CORRECT IMAGE #
#################
#Allow images access
#chmod -R 755 /whoogle/app
#Allow manifest access
#sed -i 's|manifest.json">|manifest.json" crossorigin="use-credentials">|g' /whoogle/app/templates/index.html

#Allow ingress
sed -i "1a export WHOOGLE_URL_PREFIX=\'$(bashio::addon.ingress_entry)\'" /etc/cont-init.d/99-run.sh

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

dns_host=127.0.0.11
sed -i "s/%%dns_host%%/${dns_host}/g" /etc/nginx/includes/resolver.conf
