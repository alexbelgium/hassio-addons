#!/usr/bin/with-contenv bashio

######################
# MOUNT LOCAL SHARES #
######################

bashio::log.info 'Mounting external hdd...'

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
    bashio::require.unprotected
    MOREDISKS=$(bashio::config 'localdisks')
    bashio::log.info "Local Disks mounting.. ${MOREDISKS}" && \
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
        bashio::log.info "Mount ${disk}"
        mkdir -p /share/$disk && \
            if [ ! -d /share/$disk ]; then
              echo "Creating /share/$disk"
              mkdir -p /share/$disk
              chown -R abc:abc /share/$disk
            fi
            mount /dev/$disk /share/$disk && \
            bashio::log.info "Success! Mounted to /nmt/$disk"  
    done || \
    bashio::log.warning "Protection mode is ON. Unable to mount local drives!"
fi
