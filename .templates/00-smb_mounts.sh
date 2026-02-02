#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2001,SC2015,SC2086,SC2154

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
  MOUNTED=false
  ERROR_MOUNT=false
  mountpoint="/mnt/$diskname"

  # Not mounted → not an error for this function
  if ! mountpoint -q "$mountpoint"; then
    return 0
  fi

  # ---- Write test function ----
  _test_write() {
    local testfile="$mountpoint/.writetest_$$"
    if : > "$testfile" 2>/dev/null; then
      rm -f "$testfile"
      return 0
    else
      return 1
    fi
  }

  # First write test
  if _test_write; then
    MOUNTED=true
    return 0
  fi

  # ---- CIFS fallback check ----
  if [[ "$FSTYPE" == "cifs" && "$MOUNTOPTIONS" != *"noserverino"* ]]; then
    echo "... retrying mount with noserverino"
    MOUNTOPTIONS="${MOUNTOPTIONS},noserverino"

    umount "$mountpoint" 2>/dev/null
    if mount_drive "$MOUNTOPTIONS"; then
      # retest with new options
      if _test_write; then
        MOUNTED=true
        return 0
      fi
    fi
  fi

  # ---- Final: mounted but not writable ----
  ERROR_MOUNT=true
  bashio::log.fatal "Disk mounted, but cannot write. Check permissions/export options and UID/GID mapping."
  return 1
}

mount_drive() {
  MOUNTED=true
  MOUNTOPTIONS="$1"

  if [[ "$FSTYPE" == "cifs" ]]; then
    mount -t cifs -o "$MOUNTOPTIONS" "$disk" "/mnt/$diskname" 2>"$ERRORCODE_FILE" || MOUNTED=false
  elif [[ "$FSTYPE" == "nfs" ]]; then
    mount -t nfs -o "$MOUNTOPTIONS" "$disk" "/mnt/$diskname" 2>"$ERRORCODE_FILE" || MOUNTED=false
  fi

  if [[ "$MOUNTED" == "true" ]]; then
    test_mount
  fi
}

# Retry ladder: SMB3 -> SMB2 when mount returns EINVAL (22)
retry_cifs_with_vers_ladder_on_einval() {
  [[ "${FSTYPE:-}" == "cifs" ]] || return 0
  [[ "${MOUNTED:-false}" == "false" ]] || return 0

  local err
  err="$(cat "$ERRORCODE_FILE" 2>/dev/null || true)"

  if ! echo "$err" | grep -q "mount error(22)"; then
    return 0
  fi

  bashio::log.warning "...... EINVAL (22): trying SMB dialect ladder (3.x -> 2.x)."

  local base_opts try_opts vers

  base_opts="$MOUNTOPTIONS"
  base_opts="$(echo "$base_opts" | sed -E 's/,vers=[^,]+//g; s/,sec=[^,]+//g')"

  for vers in "3.1.1" "3.02" "3.0" "2.1" "2.0"; do
    if [[ "$MOUNTED" == "false" ]]; then
      try_opts="${base_opts},vers=${vers}"
      mount_drive "$try_opts"
    fi
  done

  # Reduce option set if dialect ladder did not help (still EINVAL often)
  if [[ "$MOUNTED" == "false" ]]; then
    bashio::log.warning "...... still failing after vers ladder; retrying with reduced CIFS options."
    base_opts="$MOUNTOPTIONS"
    base_opts="$(echo "$base_opts" | sed -E 's/,vers=[^,]+//g; s/,sec=[^,]+//g')"
    base_opts="${base_opts//,mfsymlinks/}"
    base_opts="${base_opts//,nobrl/}"
    base_opts="$(echo "$base_opts" | sed -E 's/,iocharset=[^,]+//g')"

    for vers in "2.1" "2.0"; do
      if [[ "$MOUNTED" == "false" ]]; then
        try_opts="${base_opts},vers=${vers}"
        mount_drive "$try_opts"
      fi
    done

    if [[ "$MOUNTED" == "false" ]]; then
      for vers in "2.1" "2.0"; do
        if [[ "$MOUNTED" == "false" ]]; then
          try_opts="${base_opts},vers=${vers},sec=ntlmssp"
          mount_drive "$try_opts"
        fi
      done
    fi
  fi

  return 0
}

########################
# MOUNT NETWORK SHARES #
########################

if bashio::config.has_value 'networkdisks'; then

  echo "Mounting network share(s)..."

  MOREDISKS="$(bashio::config 'networkdisks')"
  USERNAME="$(bashio::config 'cifsusername')"
  PASSWORD="$(bashio::config 'cifspassword')"

  SMBVERS=""
  SECVERS=""
  CHARSET=",iocharset=utf8"

  # Clean data (keeps NFS entries intact)
  MOREDISKS="$(echo "$MOREDISKS" | sed -E 's/[[:space:]]*,[[:space:]]*/,/g; s/^[[:space:]]+//; s/[[:space:]]+$//')"

  # CIFS domain/workgroup
  DOMAINCLIENT=""
  CIFSDOMAIN=""
  if bashio::config.has_value 'cifsdomain'; then
    CIFSDOMAIN="$(bashio::config 'cifsdomain')"
    echo "... using domain $CIFSDOMAIN"
    DOMAINCLIENT="--workgroup=$CIFSDOMAIN"
  fi

  # UID/GID for CIFS mapping
  PUID=",uid=$(id -u)"
  PGID=",gid=$(id -g)"
  if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
    echo "... using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
    PUID=",uid=$(bashio::config 'PUID')"
    PGID=",gid=$(bashio::config 'PGID')"
  fi

  # ----------------------------
  # FIX: robust comma-splitting
  # ----------------------------
  IFS=',' read -r -a DISK_LIST <<< "$MOREDISKS"

  for disk in "${DISK_LIST[@]}"; do
    CRED_FILE=""
    cleanup_cred

    # FIX: tolerate CRLF / trailing \r
    disk="${disk//$'\r'/}"

    disk="$(echo "$disk" | sed 's,/$,,')"
    disk="${disk//"\040"/ }"

    # Detect FS type
    FSTYPE="cifs"
    if [[ "$disk" =~ ^nfs:// ]]; then
      FSTYPE="nfs"
      disk="${disk#nfs://}"
    elif [[ "$disk" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/.+ ]]; then
      FSTYPE="nfs"
    fi

    # Server for reachability checks
    if [[ "$FSTYPE" == "cifs" ]]; then
      server="$(echo "$disk" | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n 1)"
    else
      server="${disk%%:*}"
    fi

    diskname="$disk"
    diskname="${diskname//\\//}"
    diskname="${diskname##*/}"

    ERRORCODE_FILE="/tmp/mount_error_${diskname//[^a-zA-Z0-9._-]/_}.log"
    : >"$ERRORCODE_FILE" || true

    MOUNTED=false
    SMBVERS_FORCE=""
    SECVERS_FORCE=""
    SMBVERS=""
    SECVERS=""

    echo "... mounting ($FSTYPE) $disk"

    # Validation
    if [[ "$FSTYPE" == "cifs" ]]; then
      if [[ ! "$disk" =~ ^//[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/.+ ]]; then
        bashio::log.fatal "...... invalid CIFS path \"$disk\". Use //123.12.12.12/sharedfolder,//123.12.12.12/sharedfolder2"
        echo "Invalid CIFS path structure: $disk" >"$ERRORCODE_FILE" || true
        continue
      fi
    else
      if [[ ! "$disk" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/.+ ]]; then
        bashio::log.fatal "...... invalid NFS path \"$disk\". Use 123.12.12.12:/export/path"
        echo "Invalid NFS path structure: $disk" >"$ERRORCODE_FILE" || true
        continue
      fi
    fi

    mkdir -p "/mnt/$diskname"
    chown root:root "/mnt/$diskname"

    # CIFS: credentials file (avoids commas/special chars in password)
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

    # First mount attempt (no vers pinned yet; we will correct on EINVAL via ladder)
    if [[ "$FSTYPE" == "cifs" ]]; then
      mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}"
      if [[ "$MOUNTED" == "false" ]]; then
        retry_cifs_with_vers_ladder_on_einval
      fi
    else
      mount_drive "rw,nfsvers=4.2,proto=tcp,hard,timeo=600,retrans=2"
    fi

    # Deeper analysis if failed
    if [[ "$MOUNTED" == "false" ]]; then
      if [[ "$FSTYPE" == "cifs" ]]; then
        # SMB port check
        if command -v nmap >/dev/null 2>&1; then
          output="$(nmap -F "$server" -T5 -oG - 2>/dev/null || true)"
          if ! echo "$output" | grep -q "445/open"; then
            if echo "$output" | grep -q "/open"; then
              bashio::log.fatal "...... $server is reachable but SMB port not opened, stopping script"
            else
              bashio::log.fatal "...... fatal : $server not reachable, is it correct"
            fi
            cleanup_cred
            rm -f "$ERRORCODE_FILE" 2>/dev/null || true
            continue
          fi
          echo "...... $server is confirmed reachable"
        else
          bashio::log.warning "...... nmap not available; skipping SMB port reachability test"
        fi

        # Credentials test (use SERVER, not share path)
        if command -v smbclient >/dev/null 2>&1; then
          OUTPUT="$(smbclient -t 2 -L "$server" -U "$USERNAME%$PASSWORD" -c "exit" $DOMAINCLIENT 2>&1 || true)"

          if echo "$OUTPUT" | grep -q "LOGON_FAILURE"; then
            bashio::log.fatal "...... incorrect Username, Password, or Domain! Script will stop."
            cleanup_cred
            rm -f "$ERRORCODE_FILE" 2>/dev/null || true
            bashio::addon.stop
          elif echo "$OUTPUT" | grep -q "tree connect failed" || echo "$OUTPUT" | grep -q "NT_STATUS_CONNECTION_DISCONNECTED"; then
            echo "... using SMBv1"
            bashio::log.warning "...... share reachable only with legacy SMBv1 (NT1) negotiation. Forcing SMBv1 options."
            SMBVERS_FORCE=",vers=1.0"
            SECVERS_FORCE=",sec=ntlm"
          elif ! echo "$OUTPUT" | grep -q "Disk"; then
            bashio::log.fatal "...... no shares found. Invalid or inaccessible SMB path?"
          else
            echo "...... credentials are valid"
          fi
        else
          bashio::log.warning "...... smbclient not available; skipping SMB credential test"
        fi

        # SMB version detect (best effort)
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
        elif command -v smbclient >/dev/null 2>&1 && smbclient -t 2 -L "$server" -m NT1 -N $DOMAINCLIENT -c "exit" &>/dev/null; then
          echo "...... SMB version : only SMBv1 is supported, this can lead to issues"
          SECVERS=",sec=ntlm"
          SMBVERS=",vers=1.0"
        else
          # IMPORTANT: deterministic fallback (so we don't depend on kernel defaults)
          echo "...... SMB version : couldn't detect, falling back to SMB3->SMB2 ladder on EINVAL"
          SMBVERS=",vers=3.1.1"
        fi

        # Apply forced SMBv1 if needed
        if [[ -n "$SMBVERS_FORCE" ]]; then
          [[ -z "$SMBVERS" ]] && SMBVERS="$SMBVERS_FORCE"
          [[ -z "$SECVERS" ]] && SECVERS="$SECVERS_FORCE"
        fi

        # Try security modes (keeping detected/forced SMBVERS)
        SECVERS_BASE="$SECVERS"
        for SECTRY in "$SECVERS_BASE" ",sec=ntlmv2" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5" ",sec=ntlm" ",sec=ntlmv2i"; do
          if [[ "$MOUNTED" == "false" ]]; then
            mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECTRY}${PUID}${PGID}${CHARSET}"
          fi
        done

        # If still EINVAL, step down SMB3 -> SMB2
        if [[ "$MOUNTED" == "false" ]]; then
          retry_cifs_with_vers_ladder_on_einval
        fi

      else
        # NFS ports check and fallback versions
        if command -v nmap >/dev/null 2>&1; then
          output="$(nmap -F "$server" -T5 -oG - 2>/dev/null || true)"
          if ! echo "$output" | grep -Eq '(2049|111)/open'; then
            bashio::log.fatal "...... $server is reachable but NFS ports not open"
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

    # Finalization / messages
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
      if [[ "$FSTYPE" == "cifs" ]]; then
        bashio::log.fatal "Error, unable to mount $disk to /mnt/$diskname with username $USERNAME. Please check share path, username/password/domain; try UID/GID 0."
        bashio::log.fatal "Here is some debugging info :"
        if command -v smbclient >/dev/null 2>&1; then
          smbclient -t 2 -L "$server" -U "$USERNAME%$PASSWORD" -c "exit" $DOMAINCLIENT || true
        else
          bashio::log.warning "smbclient not available; cannot print SMB debugging info"
        fi

        # last-ditch: minimal CIFS options (still uses credentials file)
        mount_drive "rw,credentials=${CRED_FILE}${PUID}${PGID}"
        if [[ "$MOUNTED" == "false" ]]; then
          retry_cifs_with_vers_ladder_on_einval
        fi
      else
        bashio::log.fatal "Error, unable to mount NFS share $disk to /mnt/$diskname. Please check export path and allowlist for this client."
        mount_drive "rw"
      fi

      ERR_READ="$(cat "$ERRORCODE_FILE" 2>/dev/null || true)"
      bashio::log.fatal "Error read : ${ERR_READ:-unknown error}, addon will stop in 1 min"

      umount "/mnt/$diskname" 2>/dev/null || true
      rmdir "/mnt/$diskname" 2>/dev/null || true
      cleanup_cred
      rm -f "$ERRORCODE_FILE" 2>/dev/null || true

      bashio::addon.stop
    fi
  done
fi
