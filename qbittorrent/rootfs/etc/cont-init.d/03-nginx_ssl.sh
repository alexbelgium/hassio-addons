#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

################
# SSL CONFIG   #
################

if bashio::config.true 'ssl'; then
    bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"

    # Enable ssl in script
    sed -i "1a ENABLE_SSL=yes" /etc/cont-init.d/04-qbittorrent-setup.sh

    #set variables
    CERTFILE=$(bashio::config 'certfile')
    CERTFILE="${CERTFILE:-null}"
    KEYFILE=$(bashio::config 'keyfile')
    KEYFILE="${KEYFILE:-null}"

    # Correct certificate file
    if [ ! -f /ssl/"$CERTFILE" ]; then
        bashio::log.warning "... CERTFILE option not found or valid, using self-generated /config/qBittorrent/config/WebUICertificate.crt"
    else
        chmod 744 /ssl/"$CERTFILE"
        sed -i "s|/config/qBittorrent/config/WebUICertificate.crt|/ssl/$CERTFILE|g" /etc/cont-init.d/04-qbittorrent-setup.sh
        sed -i "s|WebUICertificate.crt|$CERTFILE|g" /etc/cont-init.d/04-qbittorrent-setup.sh
    fi
    
    # Correct keyfile
    if [ ! -f /ssl/"$KEYFILE" ]; then
        bashio::log.warning "... KEYFILE option not found or valid, using self-generated /config/qBittorrent/config/WebUICertificate.crt"
    else
        chmod 744 /ssl/"$KEYFILE"
        sed -i "s|/config/qBittorrent/config/WebUIKey.key|/ssl/$KEYFILE|g" /etc/cont-init.d/04-qbittorrent-setup.sh
        sed -i "s|WebUIKey.key|$KEYFILE|g" /etc/cont-init.d/04-qbittorrent-setup.sh
    fi

    # Set nginx protocol
    qbittorrent_protocol=https
else
    # Disable ssl in script
    sed -i "1a ENABLE_SSL=no" /etc/cont-init.d/04-qbittorrent-setup.sh
    # Prepare ingress
    qbittorrent_protocol="http"
    # Correct qBittorrent.conf
    sed -i "/HTTPS/d" /config/qBittorrent/config/qBittorrent.conf
fi

#################
# NGINX SETTING #
#################

cp /etc/nginx/templates/ingress.gtpl /etc/nginx/servers/ingress.conf

sed -i "s|{{ .interface }}|$(bashio::addon.ip_address)|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .port }}|$(bashio::addon.ingress_port)|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .protocol }}|${qbittorrent_protocol}|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .certfile }}|$(bashio::config 'certfile')|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .keyfile }}|$(bashio::config 'keyfile')|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .ssl }}|$(bashio::config 'ssl')|g" /etc/nginx/servers/ingress.conf
