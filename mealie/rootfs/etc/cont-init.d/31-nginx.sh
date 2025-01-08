#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'ssl'; then

    bashio::log.info "Add ssl"

    # Validate ssl
    bashio::config.require.ssl

    # Adapt nginx template
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    sed -i "s|%%certfile%%|${certfile}|g" /etc/nginx/servers/ssl.conf
    sed -i "s|%%keyfile%%|${keyfile}|g" /etc/nginx/servers/ssl.conf
    sed -i "s|9001;|9001 ssl;|g" /etc/nginx/servers/ssl.conf

else

    sed -i "/ssl/d" /etc/nginx/servers/ssl.conf

fi

bashio::log.info "Adapting for ingress"

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
base_path="/mealie/"
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%base_subpath%%|${base_path}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%base_subpath%%|${base_path}|g" /etc/nginx/servers/ssl.conf

if bashio::config.has_value "BASE_URL"; then
    sed -i "s|%%BASE_URL%%|$(bashio::config "BASE_URL"):$(bashio::addon.port 9001)|g" /etc/nginx/servers/ssl.conf
else
    sed -i "/BASE_URL/d" /etc/nginx/servers/ssl.conf
fi
