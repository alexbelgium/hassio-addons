#!/usr/bin/with-contenv bashio

######################
# MOUNT LOCAL SHARES #
######################

bashio::log.info 'Mounting external hdd...'

# Mount local Share if configured
if bashio::config.has_value 'localdisks'; then

  MOREDISKS=$(bashio::config 'localdisks')
  bashio::log.info "Local Disks mounting..."

  # Separate comma separated values
  for disk in ${MOREDISKS//,/ }; do
    # Mount each disk
    mkdir -p /mnt/$disk
    chown -R $(id -u):$(id -g) /mnt/$disk
    [ -d /share/$disk ] && mount /dev/$disk /share/$disk || true
    mount /dev/$disk /mnt/$disk && bashio::log.info "Success! $disk mounted to /mnt/$disk" || (bashio::log.fatal "Unable to mount local drives!" && rmdir /mnt/$disk)
  done
fi
