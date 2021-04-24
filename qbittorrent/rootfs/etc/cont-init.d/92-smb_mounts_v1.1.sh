#!/usr/bin/with-contenv bashio

####################
# MOUNT SMB SHARES #
####################
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
      diskname=${disk//\\//} #replace \ with /
      diskname=${diskname##*/} # Get only last part of the name
      mkdir -p /mnt/$diskname  # Create dir
      chown -R root:root /mnt/$diskname  # Permissions
      mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD$SMBVERS $disk /mnt/$diskname && \
      bashio::log.info "... $disk successfully mounted to /mnt/$diskname"

      # if Fail test smbv1
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=1.0 $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$diskname" && \
        bashio::log.error "Your smb share uses smbv1. Please check the relevant option in the addons options." # Mount share
        true
      fi

      # Test smbv2.1
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=2.1 $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$diskname" && \
        bashio::log.error "Your smb share uses smbv2.1, please remove smbv1 option."
        true
      fi

      # Test smbv3
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=3.0 $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$diskname" && \
        bashio::log.error "Your smb share uses smbv3."
        true
      fi

      # Test ntlmv2
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,sec=ntlmv2 $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$diskname" && \
        bashio::log.error "Your smb share requires ntlmv2."
        true
      fi

      # if still fail 
      if [ $? != 0 ]; then
        bashio::log.error "Unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD . Please check your remote share path, the username and password, and try to check the smbv1 box in option if your share is using smb v1" # Mount share
      fi

    done
fi
