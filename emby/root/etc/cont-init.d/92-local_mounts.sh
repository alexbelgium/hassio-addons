#!/usr/bin/with-contenv bashio

######################
# MOUNT LOCAL SHARES #
######################
MOUNTPOINTS="share"

bashio::log.info 'Mounting external hdd...'

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
  MOREDISKS=$(bashio::config 'localdisks')
  bashio::log.info "Local Disks mounting.. ${MOREDISKS}" &&
    # Separate comma separated values
    for disk in ${MOREDISKS//,/ }; do
      bashio::log.info "Mount ${disk}"
      mkdir -p /$MOUNTPOINTS/$disk &&
        if [ ! -d /$MOUNTPOINTS/$disk ]; then
          echo "Creating /$MOUNTPOINTS/$disk"
          mkdir -p /$MOUNTPOINTS/$disk
          chown -R abc:abc /$MOUNTPOINTS/$disk
        fi
      mount /dev/$disk /$MOUNTPOINTS/$disk &&
        bashio::log.info "Success! Mounted to /$MOUNTPOINTS/$disk"
    done ||
    bashio::log.warning "Unable to mount local drives!"
fi
