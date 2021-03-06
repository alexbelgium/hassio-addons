#!/usr/bin/with-contenv bashio

#########################
# MOUNT SMB SHARES v1.0 #
#########################
if bashio::config.has_value 'networkdisks'; then
    # Mount CIFS Share if configured and if Protection Mode is active
    bashio::log.info 'Mounting smb share(s)...'

    # Define variables 
    MOREDISKS=$(bashio::config 'networkdisks')
    CIFS_USERNAME=$(bashio::config 'cifsusername')
    CIFS_PASSWORD=$(bashio::config 'cifspassword')

    # Allow SMB1
    if bashio::config.true 'smbv1'; then
      SMBVERS=",vers=1.0"
    else
      SMBVERS=",vers=2.1"
    fi

    # Mounting disks
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
      disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
      diskname=${disk##*/} # Get only last part of the name
      mkdir -p /mnt/$diskname  # Create dir
      chown -R root:root /mnt/$diskname  # Permissions
      mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD$SMBVERS $disk /mnt/$diskname && \
      bashio::log.info "... $disk successfully mounted to /mnt/$diskname" || bashio::log.error "Unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD" # Mount share
    done || true
fi
