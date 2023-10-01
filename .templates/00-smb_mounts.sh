#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=

####################
# MOUNT SMB SHARES #
####################
if bashio::config.has_value 'networkdisks'; then

    echo 'Mounting smb share(s)...'

    # Define variables
    MOREDISKS=$(bashio::config 'networkdisks')
    CIFS_USERNAME=$(bashio::config 'cifsusername')
    CIFS_PASSWORD=$(bashio::config 'cifspassword')
    SMBVERS=""
    SMBDEFAULT=""
    SECVERS=""
    CHARSET=""
    DOMAINVAR=""

    # Clean data
    MOREDISKS=${MOREDISKS// \/\//,\/\/}
    MOREDISKS=${MOREDISKS//, /,}
    MOREDISKS=${MOREDISKS// /"\040"}

    # Is domain set
    if bashio::config.has_value 'cifsdomain'; then
        echo "... using domain $(bashio::config 'cifsdomain')"
        DOMAIN=",domain=$(bashio::config 'cifsdomain')"
    else
        DOMAIN=""
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

    # Mounting disks
    # shellcheck disable=SC2086
    for disk in ${MOREDISKS//,/ }; do # Separate comma separated values

        # Clean name of network share
        # shellcheck disable=SC2116,SC2001
        disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
        disk="${disk//"\040"/ }"            #replace \040 with
        diskname="${disk//\\//}"            #replace \ with /
        diskname="${diskname##*/}"          # Get only last part of the name
        MOUNTED=false

        echo "... mounting $disk"

        # Data validation
        if [[ ! "$disk" =~ ^.*+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[/]+.*+$ ]]; then
            bashio::log.fatal "The structure of your \"networkdisks\" option : \"$disk\" doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2. If you don't use it, you can simply remove the text, this will avoid this error message in the future."
            break 2
        fi

        # Prepare mount point
        mkdir -p /mnt/"$diskname"
        chown root:root /mnt/"$diskname"
       
        # Extract ip part of server for further manipulation
        server="$(echo "$disk" | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
        
        # Does server exists
        if command -v "nc" &>/dev/null; then
            # test if smb port is open
            if ! nc -w 1 -z "$server" 445 2>/dev/null; then
                # test with ping also if different port is used
                echo "... warning : SMB port not opened, trying ping"
                if ! ping -w 1 -c 1 "$server" >/dev/null; then
                    # Try smbclient (last as slowest)
                    echo "... warning : ping not successful, trying smbclient"
                    if ! smbclient -t 1 -L "$server" -N &>/dev/null; then
                        bashio::log.fatal "... your server $server from $disk doesn't seem reachable, script will stop"
                        break
                    fi
                fi
            fi
        fi
        
        # Quickly try to mount with defaults
        mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$CIFS_USERNAME,password=${CIFS_PASSWORD},nobrl$SMBVERS$SECVERS$PUID$PGID$CHARSET$DOMAINVAR" "$disk" /mnt/"$diskname" 2>ERRORCODE \
        && MOUNTED=true && MOUNTOPTIONS="$SMBVERS$SECVERS$PUID$PGID$CHARSET$DOMAINVAR" || MOUNTED=false

        # Deeper analysis if failed
        if [ "$MOUNTED" = false ]; then
        
        # Try smbv1
        if smbclient -t 2 -L "$server" -m NT1 -N &>/dev/null; then
            echo "... only SMBv1 is supported, trying it"
            SMBDEFAULT=",vers=1.0"
        fi

        # if Fail test different smb and sec versions
        echo "... looking for the optimal parameters for mounting"
        if [ "$MOUNTED" = false ]; then

            # Test with domain, remove otherwise
            ####################################
            for DOMAINVAR in "$DOMAIN" ",domain=WORKGROUP" ""; do

                # Test with PUIDPGID, remove otherwise
                ######################################
                for PUIDPGID in "$PUID$PGID" "$PUID$PGID,forceuid,forcegid" ""; do

                    # Test with iocharset utf8, remove otherwise
                    ############################################
                    for CHARSET in ",iocharset=utf8" ""; do

                        # Test with different SMB versions
                        ##################################
                        for SMBVERS in "$SMBDEFAULT" ",vers=3" ",vers=3.2" ",vers=3.0" ",vers=2.1" ",nodfs"; do

                            # Test with different security versions
                            #######################################
                            for SECVERS in "" ",sec=ntlmv2" ",sec=ntlm" ",sec=ntlmv2i" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5"; do
                                if [ "$MOUNTED" = false ]; then
                                    mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$CIFS_USERNAME,password=${CIFS_PASSWORD},nobrl$SMBVERS$SECVERS$PUIDPGID$CHARSET$DOMAINVAR" "$disk" /mnt/"$diskname" 2>ERRORCODE \
                                        && MOUNTED=true && MOUNTOPTIONS="$SMBVERS$SECVERS$PUIDPGID$CHARSET$DOMAINVAR" || MOUNTED=false
                                fi
                            done

                        done

                    done

                done

            done
        fi

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
            (umount "/mnt/$diskname" && mount -t cifs -o "iocharset=utf8,rw,file_mode=0775,dir_mode=0775,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$MOUNTOPTIONS,noserverino" "$disk" /mnt/"$diskname" && bashio::log.warning "noserverino option used")

            # Alert if smbv1
            if [[ "$MOUNTOPTIONS" == *"1.0"* ]]; then
                bashio::log.warning ""
                bashio::log.warning "Your smb system requires smbv1. This is an obsolete protocol. Please correct this to prevent issues."
                bashio::log.warning ""
            fi

        else
            # Mounting failed messages
            bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID"
            bashio::log.fatal "Here is some debugging info :"

            # Provide debugging info
            smbclient -t 5 -L $disk -U "$CIFS_USERNAME%$CIFS_PASSWORD"

            # Error code
            mount -t cifs -o "rw,file_mode=0775,dir_mode=0775,username=$CIFS_USERNAME,password=${CIFS_PASSWORD},nobrl$DOMAINVAR" "$disk" /mnt/"$diskname" 2>ERRORCODE || MOUNTED=false
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
