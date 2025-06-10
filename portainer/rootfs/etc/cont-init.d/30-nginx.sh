#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

#declare admin_port
declare portainer_protocol=http

# Generate Ingress configuration
if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    portainer_protocol=https
    sed -i "s|9000|9443|g" /etc/nginx/includes/upstream.conf
    sed -i "s|9000|9443|g" /etc/services.d/nginx/run
    sed -i "s|9099 default_server|9099 ssl|g" /etc/nginx/templates/ingress.gtpl
    sed -i '7 i ssl_certificate /ssl/{{ .certfile }};' /etc/nginx/templates/ingress.gtpl
    sed -i '7 i ssl_certificate_key /ssl/{{ .keyfile }};' /etc/nginx/templates/ingress.gtpl
    bashio::log.info "Ssl enabled, please use https for connection"
fi

bashio::var.json \
    interface "$(bashio::addon.ip_address)" \
    port "^$(bashio::addon.ingress_port)" \
    protocol "${portainer_protocol}" \
    certfile "$(bashio::config 'certfile')" \
    keyfile "$(bashio::config 'keyfile')" \
    ssl "^$(bashio::config 'ssl')" \
                                   | tempio \
    -template /etc/nginx/templates/ingress.gtpl \
    -out /etc/nginx/servers/ingress.conf
