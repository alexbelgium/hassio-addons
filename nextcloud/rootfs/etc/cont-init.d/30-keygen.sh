#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.true 'use_own_certs'; then

    bashio::log.info "Using referenced ssl certificates..."
    CERTFILE=$(bashio::config 'certfile')
    KEYFILE=$(bashio::config 'keyfile')

    #Check if files exist
    echo "... checking if referenced files exist"
    [ ! -f /ssl/"$CERTFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$CERTFILE not found" && bashio::exit.nok
    [ ! -f /ssl/"$KEYFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$KEYFILE not found" && bashio::exit.nok

else
    mkdir -p /ssl/nextcloud/keys
    bashio::log.info "No ssl certificates set. Auto generating ones..."
    SUBJECT="/C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*"
    openssl req -new -x509 -days 3650 -nodes -out /ssl/nextcloud/keys/cert.crt -keyout /ssl/nextcloud/keys/cert.key -subj "$SUBJECT"
    CERTFILE="nextcloud/keys/cert.crt"
    KEYFILE="nextcloud/keys/cert.key"

fi

#Sets certificates
echo "... adding ssl certs in files"
#Sets certificates
for NGINXFILE in "/data/config/nginx/ssl.conf" "/defaults/nginx/ssl.conf.sample" "/data/config/nginx/nginx.conf"; do
    if [ -f $NGINXFILE ]; then
        LINE=$(sed -n "/ssl_certificate /=" $NGINXFILE)
        if [[ -n "$LINE" ]]; then
            sed -i "/ssl_certificate/ d" $NGINXFILE
            sed -i "$LINE i ssl_certificate_key /ssl/$KEYFILE;" $NGINXFILE
            sed -i "$LINE i ssl_certificate /ssl/$CERTFILE;" $NGINXFILE
        fi
    fi
done
bashio::log.info "... done"
