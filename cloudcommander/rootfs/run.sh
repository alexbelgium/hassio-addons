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
    #bashio::require.unprotected
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

#########################
# MOUNT SMB SHARES v1.6 #
#########################
if bashio::config.has_value 'networkdisks'; then

  # Define variables
  MOREDISKS=$(bashio::config 'networkdisks')
  CIFS_USERNAME=$(bashio::config 'cifsusername')
  CIFS_PASSWORD=$(bashio::config 'cifspassword')
  MOUNTED=false
  SMBVERS=""
  SECVERS=""

  # Dont execute if still default
  [ ${MOREDISKS::1} == "<" ] && exit 0

  # Mount CIFS Share if configured and if Protection Mode is active
  bashio::log.info 'Mounting smb share(s)...'

  if bashio::config.has_value 'cifsdomain'; then
    DOMAIN=",domain=$(bashio::config 'cifsdomain')"
  else
    DOMAIN=""
  fi

  # Mounting disks
  for disk in ${MOREDISKS//,/ }; do # Separate comma separated values

    # Clean name of network share
    disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
    diskname=${disk//\\//}            #replace \ with /
    diskname=${diskname##*/}          # Get only last part of the name

    # Data validation
    if [[ ! $disk =~ ^.*+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[/]+.*+$ ]]; then
      bashio::log.fatal "The structure of your <networkdisks> doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2"
      exit 1
    fi

    # Prepare mount point
    mkdir -p /mnt/$diskname
    chown -R root:root /mnt/$diskname

    #Tries to mount with default options
    mount -t cifs -o rw,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$DOMAIN $disk /mnt/$diskname 2>ERRORCODE && MOUNTED=true || MOUNTED=false

    # if Fail test different smb and sec versions
    if [ $MOUNTED = false ]; then
      for SMBVERS in ",vers=3" ",vers=1.0" ",vers=2.1" ",vers=3.0" ",nodfs" ",uid=0,gid=0,forceuid,forcegid" ",noforceuid,noforcegid" ",${DOMAIN:-WORKGROUP}"; do
        mount -t cifs -o rw,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS $disk /mnt/$diskname 2>/dev/null && MOUNTED=true && break || MOUNTED=false
        for SECVERS in ",sec=ntlmi" ",sec=ntlmv2" ",sec=ntlmv2i" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=ntlm" ",sec=krb5i" ",sec=krb5" ",iocharset=utf8"; do
          mount -t cifs -o rw,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS$SECVERS $disk /mnt/$disk name 2>/dev/null && MOUNTED=true && break 2 && break || MOUNTED=false
        done
      done
    fi

    # Messages
    if [ $MOUNTED = true ] && [ "mountpoint -q /mnt/$diskname" ]; then
      #Test write permissions
      touch /mnt/$diskname/testaze && rm /mnt/$diskname/testaze \
      && bashio::log.info "... $disk successfully mounted to /mnt/$diskname with options $SMBVERS$SECVERS" \
      || bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw"

    else
      # Mounting failed messages
      bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID"
      bashio::log.fatal "Here is some debugging info :"

      # Provide debugging info
      smbclient -V &>/dev/null || apt-get install smbclient || apk add --no-cache samba-client
      #smbclient $disk -U $CIFS_USERNAME%$CIFS_PASSWORD  || true 
      smbclient -L $disk -U $CIFS_USERNAME%$CIFS_PASSWORD  || true

      # Error code
      bashio::log.fatal "Error read : $(<ERRORCODE)"
      rm ERRORCODE

      # clean folder
      umount /mnt/$diskname 2>/dev/null || true
      rmdir /mnt/$diskname || true
    fi

  done
fi



#################
# NGINX SETTING #
#################

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

CLOUDCMD_PREFIX=$(bashio::addon.ingress_entry)
export CLOUDCMD_PREFIX

declare ADDON_PROTOCOL=http
if bashio::config.true 'ssl'; then
ADDON_PROTOCOL=https
fi

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${CLOUDCMD_PREFIX}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
  CUSTOMOPTIONS=" $(bashio::config 'CUSTOM_OPTIONS')"
else
  CUSTOMOPTIONS=""
fi

if bashio::config.has_value 'DROPBOX_TOKEN'; then
  DROPBOX_TOKEN="--dropbox --dropbox-token $(bashio::config 'DROPBOX_TOKEN')"
else
  DROPBOX_TOKEN=""
fi

bashio::log.info "Starting..."

./usr/src/app/bin/cloudcmd.mjs '"'$DROPBOX_TOKEN$CUSTOMOPTIONS'"' & bashio::net.wait_for 8000 localhost 900 || true
bashio::log.info "Started !" 
exec nginx
