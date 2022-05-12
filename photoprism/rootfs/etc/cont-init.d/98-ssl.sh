#!/usr/bin/env bashio
# shellcheck shell=bash

###########
# SET SSL #
###########

if bashio::config.true 'use_own_certs'; then

    bashio::log.info "Using referenced ssl certificates..."
    CERTFILE=$(bashio::config 'certfile')
    KEYFILE=$(bashio::config 'keyfile')

    #Check if files exist
    echo "... checking if referenced certificates exist"    
    [ ! -f /ssl/"$CERTFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$CERTFILE not found" && bashio::exit.nok
    [ ! -f /ssl/"$KEYFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$KEYFILE not found" && bashio::exit.nok

    #Use existing certificates
    if [ -f /ssl/"$CERTFILE" ] && [ -f /ssl/"$KEYFILE" ]; then
        echo "... setting referenced certificates"
        rm /opt/photoprism/certs/cert.conf
        rm /opt/photoprism/certs/cert.key
        cp /ssl/"$CERTFILE" /opt/photoprism/certs/cert.conf
        cp /ssl/"$KEYFILE" /opt/photoprism/certs/cert.key
    fi

fi
