#!/usr/bin/env bashio

##########
# BANNER #
##########

if bashio::supervisor.ping; then
    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue " Add-on: $(bashio::addon.name)"
    bashio::log.blue " $(bashio::addon.description)"
    bashio::log.blue \
        '-----------------------------------------------------------'

    bashio::log.blue " Add-on version: $(bashio::addon.version)"
    if bashio::var.true "$(bashio::addon.update_available)"; then
        bashio::log.magenta ' There is an update available for this add-on!'
        bashio::log.magenta \
            " Latest add-on version: $(bashio::addon.version_latest)"
        bashio::log.magenta ' Please consider upgrading as soon as possible.'
    else
        bashio::log.green ' You are running the latest version of this add-on.'
    fi

    bashio::log.blue " System: $(bashio::info.operating_system)" \
        " ($(bashio::info.arch) / $(bashio::info.machine))"
    bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
    bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue \
        ' Please, share the above information when looking for help'
    bashio::log.blue \
        ' or support in, e.g., GitHub, forums or the Discord chat.'
    bashio::log.green \
        ' https://github.com/alexbelgium/hassio-addons'
    bashio::log.blue \
        '-----------------------------------------------------------'
fi

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
    bashio::log.info 'Mounting local hdd...'
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
            mount /dev/$disk /mnt && \
            bashio::log.info "Success! Mounted to /nmt/$disk"   
    done || \
    bashio::log.warning "Error, /dev/$disk couldn't be mounted. Is priviledged mode on?"
fi || true

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
    MOUNTED=false
    SMBVERS=""
    SECVERS=""

    if bashio::config.has_value 'cifsdomain'; then 
      DOMAIN=",domain=$(bashio::config 'cifsdomain')" 
    else
      DOMAIN=""
    fi
 
    # Mounting disks
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
      # Clean name of network share
      disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
      diskname=${disk//\\//} #replace \ with /
      diskname=${diskname##*/} # Get only last part of the name
      # Prepare mount point
      mkdir -p /mnt/$diskname
      chown -R root:root /mnt/$diskname
      
      #Tries to mount with default options
      mount -t cifs -o rw,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$DOMAIN $disk /mnt/$diskname 2>ERRORCODE && MOUNTED=true || MOUNTED=false
      
      # if Fail test different smb and sec versions
      if [ $MOUNTED = false ]; then
        for SMBVERS in ",vers=3" ",vers=1.0" ",vers=2.1" ",vers=3.0" ",nodfs" ",uid=0,gid=0,forceuid,forcegid" ",noforceuid,noforcegid" ",${DOMAIN}"
        do
           mount -t cifs -o rw,iocharset=utf8,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS $disk /mnt/$diskname 2>/dev/null && MOUNTED=true && break  || MOUNTED=false
           for SECVERS in ",sec=ntlmi" ",sec=ntlmv2" ",sec=ntlmv2i" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=ntlm" ",sec=krb5i" ",sec=krb5"
           do
                mount -t cifs -o rw,iocharset=utf8,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS$SECVERS $disk /mnt/$disk name 2>/dev/null && MOUNTED=true && break 2 && break || MOUNTED=false
           done
        done
      fi

      # Messages
      if [ $MOUNTED = true ]; then
        #Test write permissions
        touch /mnt/$diskname/testaze && rm /mnt/$diskname/testaze && bashio::log.info "... $disk successfully mounted to /mnt/$diskname with options $SMBVERS$SECVERS" || bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw" 
      else
        # message if still fail
        bashio::log.fatal "Unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID" # Mount share
        bashio::log.fatal "Error read : $(<ERRORCODE)" # Mount share
        rm ERRORCODE
      fi

    done
fi || true

###############
# LAUNCH APPS #
###############

bashio::log.info "The server will start. Please wait 30 seconds before the web UI is available. Enjoy !"

./usr/src/app/bin/cloudcmd.mjs
