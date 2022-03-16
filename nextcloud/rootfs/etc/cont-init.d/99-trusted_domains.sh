#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LAUNCHER="sudo -u abc php /data/config/www/nextcloud/occ" || bashio::log.info "/data/config/www/nextcloud/occ not found"
if ! bashio::fs.file_exists '/data/config/www/nextcloud/occ'; then
    LAUNCHER=$(find / -name "occ" -print -quit)
fi || bashio::log.info "occ not found"

# Make sure there is an Nextcloud installation
if [[ $($LAUNCHER -V) == *"not installed"* ]]; then
    bashio::log.warning "It seems there is no Nextcloud server installed. Please restart the addon after initialization of the user."
    exit 0
fi

####################
# Initialization   #
####################

if bashio::config.has_value 'trusted_domains'; then

    bashio::log.info "Currently set trusted domains :"
    $LAUNCHER config:system:get trusted_domains || bashio::log.info "No trusted domain set yet. The first one will be set when doing initial configuration"

    bashio::log.info "Trusted domains set in the configuration. Refreshing domains." &&
    ###################################
    # Remove previous trusted domains #
    ###################################
    bashio::log.info "... removing previously added trusted domain (except for first one created)"
    i=2
    until [ $i -gt 5 ]; do
        $LAUNCHER config:system:delete trusted_domains $i &&
        ((i = i + 1)) || exit
    done

    ###########################
    # Add new trusted domains #
    ###########################
    TRUSTEDDOMAINS=$(bashio::config 'trusted_domains')
    bashio::log.info "... alignement with trusted domains list : ${TRUSTEDDOMAINS}"
    for domain in ${TRUSTEDDOMAINS//,/ }; do # Comma separated values
        bashio::log.info "... adding ${domain}"
        $LAUNCHER config:system:set trusted_domains $i --value="${domain}"
        i=$((i + 1))
    done

    bashio::log.info "Remaining configurated trusted domains :"
    bashio::log.info "$($LAUNCHER config:system:get trusted_domains)" || exit

fi
