#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=

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

    # Mount CIFS Share if configured and if Protection Mode is active
    echo 'Mounting smb share(s)...'

    if bashio::config.has_value 'cifsdomain'; then
        DOMAIN=",domain=$(bashio::config 'cifsdomain')"
    else
        DOMAIN=""
    fi

    # Mounting disks
    # shellcheck disable=SC2086
    for disk in ${MOREDISKS//,/ }; do # Separate comma separated values

        # Clean name of network share
        # shellcheck disable=SC2116,SC2001
        disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
        diskname="${disk//\\//}"            #replace \ with /
        diskname="${diskname##*/}"          # Get only last part of the name

        # Data validation
        if [[ ! $disk =~ ^.*+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[/]+.*+$ ]]; then
            bashio::log.fatal "The structure of your \"networkdisks\" option : \"$disk\" doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2. If you don't use it, you can simply remove the text, this will avoid this error message in the future."
            exit 0
        fi

        # Prepare mount point
        mkdir -p /mnt/"$diskname"
        chown -R root:root /mnt/"$diskname"

        # Tries to mount with default options
        # shellcheck disable=SC2140
        mount -t cifs -o rw,username="$CIFS_USERNAME",password="${CIFS_PASSWORD}$DOMAIN" "$disk" /mnt/"$diskname" 2>ERRORCODE && MOUNTED=true || MOUNTED=false

        # if Fail test different smb and sec versions
        if [ "$MOUNTED" = false ]; then
            for SMBVERS in ",vers=3" ",vers=1.0" ",vers=2.1" ",vers=3.0" ",nodfs" ",uid=0,gid=0,forceuid,forcegid" ",noforceuid,noforcegid" ",${DOMAIN:-WORKGROUP}" ",noserverino"; do
                mount -t cifs -o "rw,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS" "$disk" /mnt/"$diskname" 2>/dev/null && MOUNTED=true && break || MOUNTED=false
                for SECVERS in ",sec=ntlmi" ",sec=ntlmv2" ",sec=ntlmv2i" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=ntlm" ",sec=krb5i" ",sec=krb5" ",iocharset=utf8" ",noserverino"; do
                    mount -t cifs -o "rw,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS$SECVERS" "$disk" /mnt/"$diskname" 2>/dev/null && MOUNTED=true && break 2 && break || MOUNTED=false
                done
            done
        fi

        # Messages
        if [ "$MOUNTED" = true ] && mountpoint -q /mnt/"$diskname"; then
            #Test write permissions
            # shellcheck disable=SC2015
            touch "/mnt/$diskname/testaze" && rm "/mnt/$diskname/testaze" &&
            bashio::log.info "... $disk successfully mounted to /mnt/$diskname with options $SMBVERS$SECVERS" ||
            bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw"

            # Test for serverino
            # shellcheck disable=SC2015
            touch "/mnt/$diskname/testaze" && cp "/mnt/$diskname/testaze" "/mnt/$diskname/testaze2" && rm "/mnt/$diskname/testaze2" ||
            (umount "/mnt/$diskname" && mount -t cifs -o "rw,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS$SECVERS,noserverino" "$disk" /mnt/"$diskname" && bashio::log.warning "noserverino option used")

        else
            # Mounting failed messages
            bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID"
            bashio::log.fatal "Here is some debugging info :"

            # Download smbclient
            if command -v "apk" &>/dev/null; then apk add --no-cache samba-client &>/dev/null; fi
            if command -v "apt" &>/dev/null; then apt-get install smbclient &>/dev/null; fi
            if command -v "pacman" &>/dev/null; then pacman -S smbclient; fi

            # Provide debugging info
            smbclient -L $disk -U "$CIFS_USERNAME%$CIFS_PASSWORD" || true

            # Error code
            bashio::log.fatal "Error read : $(<ERRORCODE)"
            rm ERRORCODE

            # clean folder
            umount "/mnt/$diskname" 2>/dev/null || true
            rmdir "/mnt/$diskname" || true
        fi

    done
fi
