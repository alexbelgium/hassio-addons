#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2086,SC2001,SC2015,SC2154

set -e

if ! bashio::supervisor.ping 2>/dev/null; then
    bashio::log.blue "Disabled : please use another method"
    exit 0
fi

bashio::log.notice "This script is used to mount remote smb/cifs/nfs shares. Instructions here : https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons"

####################
# DEFINE FUNCTIONS #
####################

cleanup_cred() {
    if [[ -n "${CRED_FILE:-}" && -f "${CRED_FILE:-}" ]]; then
        rm -f "$CRED_FILE" || true
    fi
    CRED_FILE=""
}

test_mount() {
    # Set initial test
    MOUNTED=false
    ERROR_MOUNT=false

    # Exit if not mounted
    if ! mountpoint -q "/mnt/$diskname"; then
        return 0
    fi

    # Exit if can't write
    [[ -e "/mnt/$diskname/testaze" ]] && rm -rf "/mnt/$diskname/testaze"
    mkdir "/mnt/$diskname/testaze" && touch "/mnt/$diskname/testaze/testaze" && rm -rf "/mnt/$diskname/testaze" || ERROR_MOUNT=true

    # Only CIFS has the noserverino fallback
    if [[ "$ERROR_MOUNT" == "true" && "$FSTYPE" == "cifs" ]]; then
        if [[ "$MOUNTOPTIONS" == *"noserverino"* ]]; then
            bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw"
        else
            MOUNTOPTIONS="${MOUNTOPTIONS},noserverino"
            echo "... testing with noserverino"
            mount_drive "$MOUNTOPTIONS"
            return 0
        fi
    fi

    # CRITICAL: for non-CIFS too, do not claim success if mounted but not writable
    if [[ "$ERROR_MOUNT" == "true" ]]; then
        MOUNTED=false
        bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check permissions/export options (rw), and UID/GID mapping."
        return 0
    fi

    # Set correctly mounted bit
    MOUNTED=true
    return 0
}

mount_drive() {
    # Define options
    MOUNTED=true
    MOUNTOPTIONS="$1"

    # Try mounting (type depends on (detected) FSTYPE)
    if [[ "$FSTYPE" == "cifs" ]]; then
        mount -t cifs -o "$MOUNTOPTIONS" "$disk" "/mnt/$diskname" 2>"$ERRORCODE_FILE" || MOUNTED=false
    elif [[ "$FSTYPE" == "nfs" ]]; then
        mount -t nfs -o "$MOUNTOPTIONS" "$disk" "/mnt/$diskname" 2>"$ERRORCODE_FILE" || MOUNTED=false
    fi

    # Test if successful
    if [[ "$MOUNTED" == "true" ]]; then
        test_mount
    fi
}

########################
# MOUNT NETWORK SHARES #
########################

if bashio::config.has_value 'networkdisks'; then

    # Alert message that it is a new code
    if [[ "$(date +"%Y%m%d")" -lt "20240201" ]]; then
        bashio::log.warning "------------------------"
        bashio::log.warning "This is a new code, please report any issues on https://github.com/alexbelgium/hassio-addons"
        bashio::log.warning "------------------------"
    fi

    echo "Mounting network share(s)..."

    ####################
    # Define variables #
    ####################

    MOREDISKS="$(bashio::config 'networkdisks')"
    USERNAME="$(bashio::config 'cifsusername')"
    PASSWORD="$(bashio::config 'cifspassword')"

    SMBVERS=""
    SECVERS=""
    CHARSET=",iocharset=utf8"

    # Clean data (keeps NFS entries intact)
    MOREDISKS=${MOREDISKS// \/\//,\/\/}
    MOREDISKS=${MOREDISKS//, /,}
    MOREDISKS=${MOREDISKS// /"\040"}

    # Is domain set (CIFS only)
    DOMAINCLIENT=""
    CIFSDOMAIN=""
    if bashio::config.has_value 'cifsdomain'; then
        CIFSDOMAIN="$(bashio::config 'cifsdomain')"
        echo "... using domain $CIFSDOMAIN"
        DOMAINCLIENT="--workgroup=$CIFSDOMAIN"
    fi

    # UID/GID (used for CIFS mount options)
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

    for disk in ${MOREDISKS//,/ }; do
        CRED_FILE=""
        cleanup_cred

        # Clean name of network share
        disk="$(echo "$disk" | sed "s,/$,,")" # Remove trailing /
        disk="${disk//"\040"/ }"             # replace \040 with space

        # Detect filesystem type by pattern
        FSTYPE="cifs"
        if [[ "$disk" =~ ^nfs:// ]]; then
            FSTYPE="nfs"
            disk="${disk#nfs://}"
        elif [[ "$disk" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/.+ ]]; then
            FSTYPE="nfs"
        fi

        # Determine server for reachability checks
        if [[ "$FSTYPE" == "cifs" ]]; then
            server="$(echo "$disk" | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n 1)"
        else
            server="${disk%%:*}"
        fi

        diskname="$disk"
        diskname="${diskname//\\//}" # replace \ with /
        diskname="${diskname##*/}"   # keep only last part of the name

        # CRITICAL: per-disk error file (avoid collisions / missing file reads)
        ERRORCODE_FILE="/tmp/mount_error_${diskname//[^a-zA-Z0-9._-]/_}.log"
        : >"$ERRORCODE_FILE" || true

        MOUNTED=false
        SMBVERS_FORCE=""
        SECVERS_FORCE=""
        SMBVERS=""
        SECVERS=""

        echo "... mounting ($FSTYPE) $disk"

        # Data validation
        if [[ "$FSTYPE" == "cifs" ]]; then
            if [[ ! "$disk" =~ ^//[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/.+ ]]; then
                bashio::log.fatal "...... the structure of your \"networkdisks\" option : \"$disk\" doesn't seem correct, please use a structure like //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2."
                echo "Invalid CIFS path structure: $disk" >"$ERRORCODE_FILE" || true
                continue
            fi
        else
            if [[ ! "$disk" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/.+ ]]; then
                bashio::log.fatal "...... invalid NFS path \"$disk\". Use a structure like 123.12.12.12:/export/path"
                echo "Invalid NFS path structure: $disk" >"$ERRORCODE_FILE" || true
                continue
            fi
        fi

        # Prepare mount point
        mkdir -p "/mnt/$diskname"
        chown root:root "/mnt/$diskname"

        # Create credentials file only for CIFS (avoids comma/special-char issues in -o)
        if [[ "$FSTYPE" == "cifs" ]]; then
            CRED_FILE="$(mktemp /tmp/cifs-cred.XXXXXX)"
            chmod 600 "$CRED_FILE"
            {
                printf 'username=%s\n' "$USERNAME"
                printf 'password=%s\n' "$PASSWORD"
                if [[ -n "${CIFSDOMAIN:-}" ]]; then
                    printf 'domain=%s\n' "$CIFSDOMAIN"
                fi
            } >"$CRED_FILE"
        fi

        # Quickly try to mount with defaults
        if [[ "$FSTYPE" == "cifs" ]]; then
            mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}"
        else
            mount_drive "rw,nfsvers=4.2,proto=tcp,hard,timeo=600,retrans=2"
        fi

        # Deeper analysis if failed
        if [[ "$MOUNTED" == "false" ]]; then

            if [[ "$FSTYPE" == "cifs" ]]; then
                # Does server exist (SMB port 445)
                if command -v nmap >/dev/null 2>&1; then
                    output="$(nmap -F "$server" -T5 -oG - 2>/dev/null || true)"
                    if ! echo "$output" | grep -q "445/open"; then
                        if echo "$output" | grep -q "/open"; then
                            bashio::log.fatal "...... $server is reachable but SMB port not opened, stopping script"
                        else
                            bashio::log.fatal "...... fatal : $server not reachable, is it correct"
                        fi
                        cleanup_cred
                        continue
                    else
                        echo "...... $server is confirmed reachable"
                    fi
                else
                    bashio::log.warning "...... nmap not available; skipping SMB port reachability test"
                fi

                # Are credentials correct (use server, not share path)
                if command -v smbclient >/dev/null 2>&1; then
                    OUTPUT="$(smbclient -t 2 -L "$server" -U "$USERNAME"%"$PASSWORD" -c "exit" $DOMAINCLIENT 2>&1 || true)"

                    if echo "$OUTPUT" | grep -q "LOGON_FAILURE"; then
                        bashio::log.fatal "...... incorrect Username, Password, or Domain! Script will stop."
                        if ! smbclient -t 2 -L "$server" -N $DOMAINCLIENT -c "exit" &>/dev/null; then
                            bashio::log.fatal "...... perhaps a workgroup must be specified"
                        fi
                        cleanup_cred
                        continue
                    elif echo "$OUTPUT" | grep -q "tree connect failed" || echo "$OUTPUT" | grep -q "NT_STATUS_CONNECTION_DISCONNECTED"; then
                        echo "... using SMBv1"
                        bashio::log.warning "...... share reachable only with legacy SMBv1 (NT1) negotiation. Forcing SMBv1 options."
                        SMBVERS_FORCE=",vers=1.0"
                        SECVERS_FORCE=",sec=ntlm"
                    elif ! echo "$OUTPUT" | grep -q "Disk"; then
                        echo "... testing path"
                        bashio::log.fatal "...... no shares found. Invalid or inaccessible SMB path?"
                    else
                        echo "...... credentials are valid"
                    fi
                else
                    bashio::log.warning "...... smbclient not available; skipping SMB credential test"
                fi

                # Extract SMB dialect from nmap and map to mount.cifs vers=
                SMBRAW=""
                if command -v nmap >/dev/null 2>&1; then
                    SMBRAW="$(
                        nmap --script smb-protocols -p 445 "$server" 2>/dev/null \
                            | awk '/SMB2_DIALECT_/ {print $NF}' \
                            | sed 's/SMB2_DIALECT_//' \
                            | tr -d '_' \
                            | sort -V | tail -n 1 || true
                    )"
                fi

                SMBVERS=""
                case "$SMBRAW" in
                    311) SMBVERS=",vers=3.1.1" ;;
                    302) SMBVERS=",vers=3.02" ;;
                    300) SMBVERS=",vers=3.0" ;;
                    210) SMBVERS=",vers=2.1" ;;
                    202|200) SMBVERS=",vers=2.0" ;;
                    *) SMBVERS="" ;;
                esac

                if [[ -n "$SMBVERS" ]]; then
                    echo "...... SMB version detected : ${SMBVERS#,vers=}"
                elif command -v smbclient >/dev/null 2>&1 && smbclient -t 2 -L "$server" -m NT1 -N $DOMAINCLIENT &>/dev/null; then
                    echo "...... SMB version : only SMBv1 is supported, this can lead to issues"
                    SECVERS=",sec=ntlm"
                    SMBVERS=",vers=1.0"
                else
                    echo "...... SMB version : couldn't detect, default used"
                    SMBVERS=""
                fi

                # Apply forced SMBv1 options when needed
                if [[ -n "$SMBVERS_FORCE" ]]; then
                    [[ -z "$SMBVERS" ]] && SMBVERS="$SMBVERS_FORCE"
                    [[ -z "$SECVERS" ]] && SECVERS="$SECVERS_FORCE"
                fi

                # Ensure Samba client allows SMBv1 when required
                if [[ "${SMBVERS}${SMBVERS_FORCE}" == *"vers=1.0"* ]]; then
                    if [[ -f /etc/samba/smb.conf ]]; then
                        bashio::log.warning "...... enabling SMBv1 support in Samba client configuration"
                        sed -i '/\[global\]/!b;n;/client min protocol = NT1/!a\
        client min protocol = NT1' /etc/samba/smb.conf || true
                    fi
                fi

                # Try with different security modes (do not overwrite SECVERS base accidentally)
                SECVERS_BASE="$SECVERS"
                for SECTRY in "$SECVERS_BASE" ",sec=ntlmv2" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5" ",sec=ntlm" ",sec=ntlmv2i"; do
                    if [[ "$MOUNTED" == "false" ]]; then
                        mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECTRY}${PUID}${PGID}${CHARSET}"
                    fi
                done

            else
                # NFS: check ports (111/2049) and try common versions
                if command -v nmap >/dev/null 2>&1; then
                    output="$(nmap -F "$server" -T5 -oG - 2>/dev/null || true)"
                    if ! echo "$output" | grep -Eq '(2049|111)/open'; then
                        bashio::log.fatal "...... $server is reachable but NFS ports not open"
                        continue
                    fi
                else
                    bashio::log.warning "...... nmap not available; skipping NFS port reachability test"
                fi

                for NFVER in 4.2 4.1 4 3; do
                    if [[ "$MOUNTED" == "false" ]]; then
                        mount_drive "rw,nfsvers=${NFVER},proto=tcp"
                    fi
                done
            fi
        fi

        # Messages / finalization
        if [[ "$MOUNTED" == "true" ]]; then
            bashio::log.info "...... $disk successfully mounted to /mnt/$diskname with options ${MOUNTOPTIONS/$PASSWORD/XXXXXXXXXX}"
            rm -f "$ERRORCODE_FILE" 2>/dev/null || true

            if [[ "$FSTYPE" == "cifs" && "$MOUNTOPTIONS" == *"vers=1.0"* ]]; then
                bashio::log.warning ""
                bashio::log.warning "Your SMB system requires SMBv1. This is an obsolete protocol. Please correct this to prevent issues."
                bashio::log.warning ""
            fi

            cleanup_cred
        else
            # Mounting failed messages
            if [[ "$FSTYPE" == "cifs" ]]; then
                bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $USERNAME. Please check remote share path, username, password, domain; try UID/GID 0."
                bashio::log.fatal "Here is some debugging info :"
                if command -v smbclient >/dev/null 2>&1; then
                    smbclient -t 2 -L "$server" -U "$USERNAME%$PASSWORD" -c "exit" $DOMAINCLIENT || true
                else
                    bashio::log.warning "smbclient not available; cannot print SMB debugging info"
                fi

                # last-ditch try: minimal options (still uses credentials file)
                SMBVERS=""
                SECVERS=""
                PUID=""
                PGID=""
                CHARSET=""
                mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}"
            else
                bashio::log.fatal "Error, unable to mount NFS share $disk to /mnt/$diskname. Please check the export path and that the NFS server allows this client (and NFSv4)."
                mount_drive "rw"
            fi

            ERR_READ="$(cat "$ERRORCODE_FILE" 2>/dev/null || true)"
            bashio::log.fatal "Error read : ${ERR_READ:-unknown error}, addon will stop in 1 min"

            # clean folder
            umount "/mnt/$diskname" 2>/dev/null || true
            rmdir "/mnt/$diskname" 2>/dev/null || true
            cleanup_cred
            rm -f "$ERRORCODE_FILE" 2>/dev/null || true

            # Stop addon
            bashio::addon.stop
        fi
    done
fi
