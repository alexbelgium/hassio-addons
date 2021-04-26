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

    if bashio::config.has_value 'cifsdomain'; then 
      DOMAIN=",domain=$(bashio::config 'cifsdomain')" 
    else
      DOMAIN=""
    fi
 
    # Mounting disks
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
      disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
      diskname=${disk//\\//} #replace \ with /
      diskname=${diskname##*/} # Get only last part of the name
      mkdir -p /mnt/$diskname  # Create dir
      chown -R root:root /mnt/$diskname  # Permissions
      mount -t cifs -o username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$DOMAIN $disk /mnt/$diskname && \
      bashio::log.info "... $disk successfully mounted to /mnt/$diskname"

      # if Fail test smbv1
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=1.0$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$diskname with smbv1"
      fi

      # Test smbv2.1
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=2.1$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$disk name with smbv2.1"
      fi

      # Test smbv3
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,vers=3.0$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$disk name with smbv3"
      fi

      # Test ntlmv2
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,sec=ntlmv2$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$disk name with ntlmv2"
      fi

      # Test ntlmv2 and smbv3
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,sec=ntlmv2,vers=2.1$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$disk name with ntlmv2 and smbv2.1"
      fi

      # Test ntlmv2 and smbv3
      if [ $? != 0 ]; then
        mount -t cifs -o username=$CIFS_USERNAME,password=$CIFS_PASSWORD,sec=ntlmv2,vers=3$DOMAIN $disk /mnt/$diskname && \
        bashio::log.info "... $disk successfully mounted to /mnt/$disk name with ntlmv2 and smbv3"
      fi

      if [ $? != 0 ]; then
        # message if still fail
        bashio::log.fatal "Unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD . Please check your remote share path, the username and password, and try to check the smbv1 box in option if your share is using smb v1" # Mount share
      else
        # test write permissions
        touch /mnt/$diskname/testaze && rm /mnt/$diskname/testaze || bashio::log.fatal "Unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw" 
      fi

    done
fi
