#!/usr/bin/with-contenv bashio

######################
# MOUNT LOCAL SHARES #
######################

bashio::log.info 'Mounting external hdd...'

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
    MOREDISKS=$(bashio::config 'localdisks')
    bashio::log.info "Local Disks mounting.. ${MOREDISKS}" && \
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
        bashio::log.info "Mount ${disk}"
        mkdir -p /mnt/$disk && \
            if [ ! -d /mnt/$disk ]; then
              echo "Creating /mnt/$disk"
              mkdir -p /mnt/$disk
              chown -R abc:abc /mnt/$disk
            fi
            mount /dev/$disk /mnt/$disk && \
            bashio::log.info "Success! Mounted to /mnt/$disk"  
    done || \
    bashio::log.warning "Unable to mount local drives!"
fi
