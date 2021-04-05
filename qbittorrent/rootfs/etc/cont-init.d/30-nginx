#!/usr/bin/with-contenv bashio

#################
# NGINX SETTING #
#################

declare admin_port
declare qbittorrent_protocol=http

# Generate Ingress configuration
if bashio::config.true 'ssl'; then
qbittorrent_protocol=https
fi

bashio::var.json \
    interface "$(bashio::addon.ip_address)" \
    port "^$(bashio::addon.ingress_port)" \
    protocol "${qbittorrent_protocol}" \
    certfile "$(bashio::config 'certfile')" \
    keyfile "$(bashio::config 'keyfile')" \
    ssl "^$(bashio::config 'ssl')" \
    | tempio \
        -template /etc/nginx/templates/ingress.gtpl \
        -out /etc/nginx/servers/ingress.conf
        
######################
# VUETORRENT INSTALL #
######################

LATEST_RELEASE=$(curl -s -L https://api.github.com/repos/wdaan/vuetorrent/releases/latest \
              | grep "browser_download_url.*zip" \
              | cut -d : -f 2,3 \
              | tr -d \" \
              | xargs) # to trim whitespaceq

curl -O -J -L $LATEST_RELEASE >/dev/null
unzip -o vuetorrent.zip -d / >/dev/null 
rm /vuetorrent.zip >/dev/null
