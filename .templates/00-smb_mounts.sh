#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=
set -e

if ! bashio::supervisor.ping 2>/dev/null; then
    bashio::log.blue "Disabled : please use another method"
    exit 0
fi

####################
# DEFINE FUNCTIONS #
####################

test_mount()  {

    # Set initial test
    MOUNTED=false
    ERROR_MOUNT=false

    # Exit if not mounted
    if ! mountpoint -q /mnt/"$diskname"; then
        return 0
  fi

    # Exit if can't write
    [[ -e "/mnt/$diskname/testaze" ]] && rm -r "/mnt/$diskname/testaze"
    # shellcheck disable=SC2015
    mkdir "/mnt/$diskname/testaze" && touch "/mnt/$diskname/testaze/testaze" && rm -r "/mnt/$diskname/testaze" || ERROR_MOUNT=true
    if [[ $ERROR_MOUNT == "true"   ]]; then
        # Test write permissions
        if [[ $MOUNTOPTIONS == *"noserverino"*   ]]; then
            bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw"
    else
            MOUNTOPTIONS="$MOUNTOPTIONS,noserverino"
            echo "... testing with noserverino"
            mount_drive "$MOUNTOPTIONS"
            return 0
    fi
  fi

    # Set correctly mounted bit
    MOUNTED=true
    return 0

}

mount_drive()  {

    # Define options
    MOUNTED=true
    MOUNTOPTIONS="$1"

    # Try mounting
    mount -t cifs -o "$MOUNTOPTIONS" "$disk" /mnt/"$diskname" 2>ERRORCODE || MOUNTED=false

    # Test if succesful
    if [[ $MOUNTED == "true"   ]]; then
        # shellcheck disable=SC2015
        test_mount
  fi

}

####################
# MOUNT SMB SHARES #
####################

if bashio::config.has_value 'networkdisks'; then

    # Alert message that it is a new code
    if [[ "$(date +"%Y%m%d")" -lt "20240201" ]]; then
        bashio::log.warning "------------------------"
        bashio::log.warning "This is a new code, please report any issues on https://github.com/alexbelgium/hassio-addons"
        bashio::log.warning "------------------------"
  fi

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
    DOMAIN=""
    DOMAINCLIENT=""
    if bashio::config.has_value 'cifsdomain'; then
        echo "... using domain $(bashio::config 'cifsdomain')"
        DOMAIN=",domain=$(bashio::config 'cifsdomain')"
        DOMAINCLIENT="--workgroup=$(bashio::config 'cifsdomain')"
  fi

    # Is  UID/GID set
    PUID=",uid=$(id -u)"
    PGID=",gid=$(id -g)"
    if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
        echo "... using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
        PUID=",uid=$(bashio::config 'PUID')"
        PGID=",gid=$(bashio::config 'PGID')"
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
        if [[ ! $disk =~ ^.*+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[/]+.*+$   ]]; then
            bashio::log.fatal "...... the structure of your \"networkdisks\" option : \"$disk\" doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2. If you don't use it, you can simply remove the text, this will avoid this error message in the future."
            touch ERRORCODE
            continue
    fi

        # Prepare mount point
        mkdir -p /mnt/"$diskname"
        chown root:root /mnt/"$diskname"

        # Quickly try to mount with defaults
        mount_drive "rw,file_mode=0775,dir_mode=0775,username=${USERNAME},password=${PASSWORD},nobrl${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}${DOMAIN}"

        # Deeper analysis if failed
        if [ "$MOUNTED" = false ]; then

            # Extract ip part of server for further manipulation
            server="$(echo "$disk" | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"

            # Does server exists
            output="$(nmap -F $server -T5 -oG -)"
            if ! echo "$output" | grep 445/open &>/dev/null; then
                if echo "$output" | grep /open &>/dev/null; then
                    bashio::log.fatal "...... $server is reachable but SMB port not opened, stopping script"
                    touch ERRORCODE
                    continue
        else
                    bashio::log.fatal "...... fatal : $server not reachable, is it correct"
                    touch ERRORCODE
                    continue
        fi
      else
                echo "...... $server is confirmed reachable"
      fi

            # Are credentials correct
            OUTPUT="$(smbclient -t 2 -L "$disk" -U "$USERNAME"%"$PASSWORD" -c "exit" $DOMAINCLIENT 2>&1 || true)"
            if echo "$OUTPUT" | grep -q "LOGON_FAILURE"; then
                bashio::log.fatal "...... incorrect Username, Password, or Domain! Script will stop."
                touch ERRORCODE
                # Should there be a workgroup
                if ! smbclient -t 2 -L $disk -N $DOMAINCLIENT -c "exit" &>/dev/null; then
                    bashio::log.fatal "...... perhaps a workgroup must be specified"
                    touch ERRORCODE
        fi
                continue
      elif       echo "$OUTPUT" | grep -q "tree connect failed" || echo "$OUTPUT" | grep -q "NT_STATUS_CONNECTION_DISCONNECTED"; then
                echo "... testing path"
                bashio::log.fatal "...... invalid or inaccessible SMB path. Script will stop."
                touch ERRORCODE
                continue
      elif       ! echo "$OUTPUT" | grep -q "Disk"; then
                echo "... testing path"
                bashio::log.fatal "...... no shares found. Invalid or inaccessible SMB path?"
      else
                echo "...... credentials are valid"
      fi

            # Extracting SMB versions and normalize output
            # shellcheck disable=SC2210,SC2094
            SMBVERS="$(nmap --script smb-protocols "$server" -p 445 2>1 | awk '/  [0-9]/' | awk '{print $NF}'  | cut -c -3 | sort -V | tail -n 1  || true)"
            # Avoid :
            SMBVERS="${SMBVERS/:/.}"
            # Manage output
            if [ -n "$SMBVERS" ]; then
                case $SMBVERS in
                    "202" | "200" | "20")
                        SMBVERS="2.0"
                        ;;
                    21)
                        SMBVERS="2.1"
                        ;;
                    302)
                        SMBVERS="3.02"
                        ;;
                    311)
                        SMBVERS="3.1.1"
                        ;;
                    "3.1")
                        echo "SMB 3.1 detected, converting to 3.0"
                        SMBVERS="3.0"
                        ;;
        esac
                echo "...... SMB version detected : $SMBVERS"
                SMBVERS=",vers=$SMBVERS"
      elif       smbclient -t 2 -L "$server" -m NT1 -N $DOMAINCLIENT &>/dev/null; then
                echo "...... SMB version : only SMBv1 is supported, this can lead to issues"
                SECVERS=",sec=ntlm"
                SMBVERS=",vers=1.0"
      else
                echo "...... SMB version : couldn't detect, default used"
                SMBVERS=""
      fi

            # Test with different security versions
            #######################################
            for SECVERS in "$SECVERS" ",sec=ntlmv2" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5" ",sec=ntlm" ",sec=ntlmv2i"; do
                if [ "$MOUNTED" = false ]; then
                    mount_drive "rw,file_mode=0775,dir_mode=0775,username=${USERNAME},password=${PASSWORD},nobrl${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}${DOMAIN}"
        fi
      done

    fi

        # Messages
        if [ "$MOUNTED" = true ]; then

            bashio::log.info "...... $disk successfully mounted to /mnt/$diskname with options ${MOUNTOPTIONS/$PASSWORD/XXXXXXXXXX}"
            # Remove errorcode
            if [ -f ERRORCODE ]; then
                rm ERRORCODE
      fi

            # Alert if smbv1
            if [[ $MOUNTOPTIONS == *"1.0"*   ]]; then
                bashio::log.warning ""
                bashio::log.warning "Your smb system requires smbv1. This is an obsolete protocol. Please correct this to prevent issues."
                bashio::log.warning ""
      fi

    else
            # Mounting failed messages
            bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $USERNAME, $PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID"
            bashio::log.fatal "Here is some debugging info :"

            # Provide debugging info
            smbclient -t 2 -L $disk -U "$USERNAME%$PASSWORD" -c "exit"

            # Error code
            SMBVERS=""
            SECVERS=""
            PUID=""
            PGID=""
            CHARSET=""
            mount_drive "rw,file_mode=0775,dir_mode=0775,username=${USERNAME},password=${PASSWORD},nobrl${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}${DOMAIN}"
            bashio::log.fatal "Error read : $(<ERRORCODE), addon will stop in 1 min"

            # clean folder
            umount "/mnt/$diskname" 2>/dev/null || true
            rmdir "/mnt/$diskname" || true

            # Stop addon
            bashio::addon.stop

    fi

  done

fi
