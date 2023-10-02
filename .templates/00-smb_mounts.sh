#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=

####################
# MOUNT SMB SHARES #
####################

if bashio::config.has_value 'networkdisks'; then

    echo 'Mounting smb share(s)...'

    ####################
    # Define variables #
    ####################
    
    # Set variables
    MOREDISKS=$(bashio::config 'networkdisks')
    USERNAME=$(bashio::config 'cifsusername')
    PASSWORD=$(bashio::config 'cifspassword')
    SMBVERS=""
    SECVERS=""
    CHARSET=",iocharset=utf8"

    # Clean data
    MOREDISKS=${MOREDISKS// \/\//,\/\/}
    MOREDISKS=${MOREDISKS//, /,}
    MOREDISKS=${MOREDISKS// /"\040"}

    # Is domain set
    if bashio::config.has_value 'cifsdomain'; then
        echo "... using domain $(bashio::config 'cifsdomain')"
        DOMAIN=",domain=$(bashio::config 'cifsdomain')"
        DOMAINCLIENT=",--workgroup=$(bashio::config 'cifsdomain')"
    else
        DOMAIN=""
        DOMAINCLIENT=""
    fi

    # Is  UID/GID set
    if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID' && [ -z ${ROOTMOUNT+x} ]; then
        echo "... using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
        PUID=",uid=$(bashio::config 'PUID')"
        PGID=",gid=$(bashio::config 'PGID')"
    else
        PUID=",uid=$(id -u)"
        PGID=",gid=$(id -g)"
    fi

    ##################
    # Mounting disks #
    ##################
    
    # shellcheck disable=SC2086
    for disk in ${MOREDISKS//,/ }; do # Separate comma separated values

        # Clean name of network share
        # shellcheck disable=SC2116,SC2001
        disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
        disk="${disk//"\040"/ }"            #replace \040 with
        diskname="${disk//\\//}"            #replace \ with /
        diskname="${diskname##*/}"          # Get only last part of the name
        MOUNTED=false

        # Start
        echo "... mounting $disk"

        # Data validation
        if [[ ! "$disk" =~ ^.*+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[/]+.*+$ ]]; then
            bashio::log.fatal "... the structure of your \"networkdisks\" option : \"$disk\" doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2. If you don't use it, you can simply remove the text, this will avoid this error message in the future."
            continue
        fi

        # Prepare mount point
        mkdir -p /mnt/"$diskname"
        chown root:root /mnt/"$diskname"

        # Quickly try to mount with defaults
        mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$USERNAME,password=${PASSWORD},nobrl$SMBVERS$SECVERS$PUID$PGID$CHARSET$DOMAIN" "$disk" /mnt/"$diskname" 2>ERRORCODE \
        && MOUNTED=true && MOUNTOPTIONS="$SMBVERS$SECVERS$PUID$PGID$CHARSET$DOMAIN" || MOUNTED=false

        # Deeper analysis if failed
        if [ "$MOUNTED" = false ]; then

            # Extract ip part of server for further manipulation
            server="$(echo "$disk" | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"

            # Does server exists
            echo "... testing that $server is reachable"
            output="$(nmap -F $server -T5 -oG -)"
            if ! echo "$output" | grep 445/open &>/dev/null; then
                if echo "$output" | grep /open &>/dev/null; then
                    bashio::log.fatal "... fatal : $server is reachable but SMB port not opened, stopping script"
                    continue
                else
                    bashio::log.fatal "... fatal : $server not reachable, is it correct"
                    continue
                fi
            fi

            # Are credentials correct
            echo "... testing credentials"
            if ! smbclient -t 2 -L $disk -U $USERNAME%$PASSWORD "$DOMAINCLIENT" &>/dev/null; then
                bashio::log.fatal "Incorrect Username or Password! Script will stop."
                continue
            fi

            # Should there be a workgroup
            echo "... testing workgroup"
            if ! smbclient -t 2 -L $disk -N "$DOMAINCLIENT" &>/dev/null; then
                bashio::log.fatal "A workgroup must perhaps be specified"
                continue
            fi

            # What is the SMB version
            echo "... detecting SMB version"
            # Extracting SMB versions and normalize output
            # shellcheck disable=SC2210,SC2094
            SMBVERS="$(nmap --script smb-protocols "$server" -p 445 2>1 | awk '/  [0-9]/' | awk '{print $NF}'  | cut -c -3 | sort -V | tail -n 1  || true)"
            # Manage output
            if [ -n "$SMBVERS" ]; then
              echo "... SMB version $SMBVERS detected"
              SMBVERS=",vers=$SMBVERS"
            elif smbclient -t 2 -L "$server" -m NT1 -N "$DOMAINCLIENT" &>/dev/null; then
              echo "... only SMBv1 is supported, this can lead to issues"
              SECVERS=",sec=ntlm"
              SMBVERS=",vers=1.0"
            else
              echo "... couldn't detect, default used"
              SMBVERS=""
            fi

             # Test with different security versions
             #######################################
             for SECVERS in "$SECVERS" ",sec=ntlmv2" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5" ",sec=ntlm" ",sec=ntlmv2i"; do
                 if [ "$MOUNTED" = false ]; then
                     mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$USERNAME,password=${PASSWORD},nobrl$SMBVERS$SECVERS$PUIDPGID$CHARSET$DOMAIN" "$disk" /mnt/"$diskname" 2>ERRORCODE \
                     && MOUNTED=true && MOUNTOPTIONS="$SMBVERS$SECVERS$PUIDPGID$CHARSET$DOMAIN" || MOUNTED=false
                 fi
             done
             
         fi

        # Messages
        if [ "$MOUNTED" = true ] && mountpoint -q /mnt/"$diskname"; then
            #Test write permissions
            # shellcheck disable=SC2015
            touch "/mnt/$diskname/testaze" && rm "/mnt/$diskname/testaze" &&
            bashio::log.info "... $disk successfully mounted to /mnt/$diskname with options $MOUNTOPTIONS" ||
            bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw"

            # Test for serverino
            # shellcheck disable=SC2015
            touch "/mnt/$diskname/testaze" && mv "/mnt/$diskname/testaze" "/mnt/$diskname/testaze2" && rm "/mnt/$diskname/testaze2" ||
            (umount "/mnt/$diskname" && mount -t cifs -o "iocharset=utf8,rw,file_mode=0775,dir_mode=0775,username=$USERNAME,password=${PASSWORD}$MOUNTOPTIONS,noserverino" "$disk" /mnt/"$diskname" && bashio::log.warning "noserverino option used")

            # Alert if smbv1
            if [[ "$MOUNTOPTIONS" == *"1.0"* ]]; then
                bashio::log.warning ""
                bashio::log.warning "Your smb system requires smbv1. This is an obsolete protocol. Please correct this to prevent issues."
                bashio::log.warning ""
            fi

        else
            # Mounting failed messages
            bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $USERNAME, $PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID"
            bashio::log.fatal "Here is some debugging info :"

            # Provide debugging info
            smbclient -t 2 -L $disk -U "$USERNAME%$PASSWORD"

            # Error code
            mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$USERNAME,password=${PASSWORD},nobrl$DOMAIN" "$disk" /mnt/"$diskname" 2>ERRORCODE || MOUNTED=false
            bashio::log.fatal "Error read : $(<ERRORCODE), addon will stop in 1 min"
            rm ERRORCODE*

            # clean folder
            umount "/mnt/$diskname" 2>/dev/null || true
            rmdir "/mnt/$diskname" || true

            sleep 1m
            bashio::addon.stop
        fi

    done

    if [ -f ERRORCODE ]; then
        rm ERRORCODE*
    fi

fi
