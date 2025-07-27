#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

# Only execute if installed
if [ -f /notinstalled ]; then exit 0; fi

# Specify launcher

LAUNCHER="sudo -u abc php /app/www/public/occ"

####################
# Initialization   #
####################

if bashio::config.has_value 'trusted_domains'; then

    bashio::log.info "Currently set trusted domains :"
    $LAUNCHER config:system:get trusted_domains || bashio::log.info "No trusted domain set yet. The first one will be set when doing initial configuration"

    bashio::log.info "Trusted domains set in the configuration. Refreshing domains." \
        &&
        ###################################
        # Remove previous trusted domains #
        ###################################
        bashio::log.info "... removing previously added trusted domain (except for first one created)"
    i=2
    until [ $i -gt 5 ]; do
        $LAUNCHER config:system:delete trusted_domains $i \
            && ((i = i + 1)) || exit
    done

    ###########################
    # Add new trusted domains #
    ###########################
    TRUSTEDDOMAINS=$(bashio::config 'trusted_domains')
    bashio::log.info "... alignement with trusted domains list : ${TRUSTEDDOMAINS}"
    for domain in ${TRUSTEDDOMAINS//,/ }; do # Comma separated values
        bashio::log.info "... adding ${domain}"
        # shellcheck disable=SC2086
        $LAUNCHER config:system:set trusted_domains $i --value="${domain}"
        i=$((i + 1))
    done

    bashio::log.info "Remaining configurated trusted domains :"
    bashio::log.info "$($LAUNCHER config:system:get trusted_domains)" || exit

fi
