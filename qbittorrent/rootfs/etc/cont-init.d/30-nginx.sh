#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

DEBUG=$(bashio::config 'TZ')
[ "$DEBUG" = "debug" ] && echo "Before declare"

#################
# NGINX SETTING #
#################

#declare admin_port
declare qbittorrent_protocol=http

[ "$DEBUG" = "debug" ] && echo "Before ssl"

# Generate Ingress configuration
if bashio::config.true 'ssl'; then
    qbittorrent_protocol=https
fi

[ "$DEBUG" = "debug" ] && echo "Before cp"

cp /etc/nginx/templates/ingress.gtpl /etc/nginx/servers/ingress.conf

[ "$DEBUG" = "debug" ] && echo "Before sed"
sed -i "s|{{ .interface }}|$(bashio::addon.ip_address)|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .port }}|$(bashio::addon.ingress_port)|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .protocol }}|${qbittorrent_protocol}|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .certfile }}|$(bashio::config 'certfile')|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .keyfile }}|$(bashio::config 'keyfile')|g" /etc/nginx/servers/ingress.conf
sed -i "s|{{ .ssl }}|$(bashio::config 'ssl')|g" /etc/nginx/servers/ingress.conf

######################
# VUETORRENT INSTALL #
######################

[ "$DEBUG" = "debug" ] && echo "Before var"
LATEST_RELEASE=$(curl -f -s --retry 5 -L https://api.github.com/repos/wdaan/vuetorrent/releases/latest |
    grep "browser_download_url.*zip" |
    cut -d : -f 2,3 |
    tr -d \" |
xargs)
[ "$DEBUG" = "debug" ] && echo "url: $LATEST_RELEASE"

[ "$DEBUG" = "debug" ] && echo "Before curl"
curl -f -s -S -O -J -L "$LATEST_RELEASE"

[ "$DEBUG" = "debug" ] && echo "Before unzip"
unzip -o vuetorrent.zip -d / >/dev/null

[ "$DEBUG" = "debug" ] && echo "Before rm"
rm vuetorrent.zip >/dev/null
