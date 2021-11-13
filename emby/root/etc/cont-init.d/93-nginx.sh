#!/usr/bin/with-contenv bashio

###############
# SSL SETTING #
###############

if bashio::config.true 'ssl'; then
    protocol=https
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    # Self generate if not found
    if [ ! -f /ssl/$certfile ] && [ ! -f /ssl/$keyfile ]; then
      bashio::log.info "No ssl certificates found. Auto generating ones..."
      SUBJECT="/C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*"
      openssl req -new -x509 -days 3650 -nodes -out /ssl/$certfile -keyout /ssl/$keyfile -subj "$SUBJECT"
    fi
    address=$(bashio::addon.ip_address)
    sed -i "s|%%interface%%|$address|g" /etc/nginx/templates/ssl.gtpl
    sed -i "s|%%certfile%%|/ssl/$certfile|g" /etc/nginx/templates/ssl.gtpl
    sed -i "s|%%certkey%%|/ssl/$keyfile|g" /etc/nginx/templates/ssl.gtpl
    mv /etc/nginx/templates/ssl.gtpl /etc/nginx/servers/ssl.conf
    bashio::log.info "ssl configured, emby will be accessible through https instead of http"
fi
