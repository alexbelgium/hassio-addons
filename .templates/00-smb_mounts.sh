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

  if ! mountpoint -q "$mountpoint"; then
    return 0
  fi

  _test_write() {
    local testfile="$mountpoint/.writetest_$$"
    if : >"$testfile" 2>/dev/null; then
      rm -f "$testfile" 2>/dev/null || true
      return 0
    else
      rm -f "$testfile" 2>/dev/null || true
      return 1
    fi
  }

  if _test_write 2>/dev/null; then
    MOUNTED=true
    return 0
  fi

  if [[ "$FSTYPE" == "cifs" && "$MOUNTOPTIONS" != *"noserverino"* ]]; then
    echo "... retrying mount with noserverino"
    MOUNTOPTIONS="${MOUNTOPTIONS},noserverino"

    umount "$mountpoint" 2>/dev/null || true
    if mount_drive "$MOUNTOPTIONS"; then
      if _test_write 2>/dev/null; then
        MOUNTED=true
        return 0
      fi
    fi
  fi

  if [[ "$FSTYPE" == "cifs" && "$MOUNTOPTIONS" != *"noperm"* ]]; then
    echo "... retrying mount with noperm"
    MOUNTOPTIONS="${MOUNTOPTIONS},noperm"

    umount "$mountpoint" 2>/dev/null || true
    if mount_drive "$MOUNTOPTIONS"; then
      if _test_write 2>/dev/null; then
        MOUNTED=true
        return 0
      fi
    fi
  fi

  MOUNTED="readonly"
  return 0
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

# Retry ladder: SMB3 -> SMB2 when mount fails due to dialect/negotiation issues
retry_cifs_with_vers_ladder_on_dialect_failure() {
  [[ "${FSTYPE:-}" == "cifs" ]] || return 0
  [[ "${MOUNTED:-false}" == "false" ]] || return 0
  [[ "${CIFS_LADDER_ATTEMPTED:-false}" == "false" ]] || return 0

  local err mountpoint
  mountpoint="/mnt/$diskname"
  err="$(cat "$ERRORCODE_FILE" 2>/dev/null || true)"

  if echo "$err" | grep -Eq 'mount error\(13\)|Permission denied|NT_STATUS_(LOGON_FAILURE|ACCESS_DENIED)|STATUS_(LOGON_FAILURE|ACCESS_DENIED)'; then
    return 0
  fi

  if ! echo "$err" | grep -Eq 'mount error\(22\)|mount error\(95\)|mount error\(112\)|Server abruptly closed the connection|does not support the SMB version|Protocol negotiation|NT_STATUS_CONNECTION_DISCONNECTED'; then
    return 0
  fi

  CIFS_LADDER_ATTEMPTED=true
  bashio::log.warning "...... CIFS negotiation/dialect failure: trying SMB dialect ladder (3.x -> 2.x -> 1.0)."

  local base_opts try_opts vers vopt sectry

  base_opts="$MOUNTOPTIONS"
  base_opts="$(echo "$base_opts" | sed -E 's/,vers=[^,]+//g; s/,sec=[^,]+//g')"

  local -a opt_variants=("" ",nounix" ",noserverino" ",nounix,noserverino")
  local -a sec_variants=("" ",sec=ntlmssp" ",sec=ntlmv2" ",sec=ntlm")
  local -a vers_variants=("3.1.1" "3.02" "3.0" "2.1" "2.0" "1.0")

  for vopt in "${opt_variants[@]}"; do
    for vers in "${vers_variants[@]}"; do
      for sectry in "${sec_variants[@]}"; do
        [[ "$MOUNTED" == "false" ]] || break
        umount "$mountpoint" 2>/dev/null || true
        try_opts="${base_opts}${vopt},vers=${vers}${sectry}"
        mount_drive "$try_opts"
      done
      [[ "$MOUNTED" == "false" ]] || break
    done
    [[ "$MOUNTED" == "false" ]] || break
  done

  if [[ "$MOUNTED" == "false" ]]; then
    bashio::log.warning "...... still failing after vers ladder; retrying with reduced CIFS options."
    base_opts="$MOUNTOPTIONS"
    base_opts="$(echo "$base_opts" | sed -E 's/,vers=[^,]+//g; s/,sec=[^,]+//g')"
    base_opts="${base_opts//,mfsymlinks/}"
    base_opts="${base_opts//,nobrl/}"
    base_opts="$(echo "$base_opts" | sed -E 's/,iocharset=[^,]+//g')"

    local -a vers_variants2=("2.1" "2.0" "1.0")
    for vopt in "${opt_variants[@]}"; do
      for vers in "${vers_variants2[@]}"; do
        for sectry in "${sec_variants[@]}"; do
          [[ "$MOUNTED" == "false" ]] || break
          umount "$mountpoint" 2>/dev/null || true
          try_opts="${base_opts}${vopt},vers=${vers}${sectry}"
          mount_drive "$try_opts"
        done
        [[ "$MOUNTED" == "false" ]] || break
      done
      [[ "$MOUNTED" == "false" ]] || break
    done

    if [[ "$MOUNTED" == "false" ]]; then
      for vopt in "${opt_variants[@]}"; do
        for vers in "${vers_variants2[@]}"; do
          [[ "$MOUNTED" == "false" ]] || break
          umount "$mountpoint" 2>/dev/null || true
          try_opts="${base_opts}${vopt},vers=${vers},sec=ntlmssp"
          mount_drive "$try_opts"
        done
        [[ "$MOUNTED" == "false" ]] || break
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

  MOREDISKS="${MOREDISKS//$'\r'/}"
  MOREDISKS="${MOREDISKS//$'\n'/,}"
  MOREDISKS="$(echo "$MOREDISKS" | sed -E 's/[[:space:]]*,[[:space:]]*/,/g; s/^[[:space:]]+//; s/[[:space:]]+$//')"

  DOMAINCLIENT=""
  CIFSDOMAIN=""
  if bashio::config.has_value 'cifsdomain'; then
    CIFSDOMAIN="$(bashio::config 'cifsdomain')"
    echo "... using domain $CIFSDOMAIN"
    DOMAINCLIENT="--workgroup=$CIFSDOMAIN"
  fi

  PUID=",uid=$(id -u)"
  PGID=",gid=$(id -g)"
  if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
    echo "... using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
    PUID=",uid=$(bashio::config 'PUID')"
    PGID=",gid=$(bashio::config 'PGID')"
  fi

  IFS=',' read -r -a DISK_LIST <<< "$MOREDISKS"

  for disk in "${DISK_LIST[@]}"; do
    CRED_FILE=""
    cleanup_cred

    disk="${disk//$'\r'/}"
    disk="$(echo "$disk" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [[ -z "$disk" ]] && continue

    disk="$(echo "$disk" | sed 's,/$,,')"
    disk="${disk//"\040"/ }"

    FSTYPE="cifs"
    if [[ "$disk" =~ ^nfs:// ]]; then
      FSTYPE="nfs"
      disk="${disk#nfs://}"
    elif [[ "$disk" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/.+ ]]; then
      FSTYPE="nfs"
    fi

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
    CIFS_LADDER_ATTEMPTED=false
    SMBVERS_FORCE=""
    SECVERS_FORCE=""
    SMBVERS=""
    SECVERS=""

    echo "... mounting ($FSTYPE) $disk"

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

    if [[ "$FSTYPE" == "cifs" ]]; then
      mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECVERS}${PUID}${PGID}${CHARSET}"
      if [[ "$MOUNTED" == "false" ]]; then
        retry_cifs_with_vers_ladder_on_dialect_failure
      fi
    else
      mount_drive "rw,nfsvers=4.2,proto=tcp,hard,timeo=600,retrans=2"
    fi

    if [[ "$MOUNTED" == "false" ]]; then
      if [[ "$FSTYPE" == "cifs" ]]; then
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

        SMBRAW=""
        SMB1_DETECTED=false
        if command -v nmap >/dev/null 2>&1; then
          NMAP_OUTPUT="$(nmap --script smb-protocols -p 445 "$server" 2>/dev/null || true)"
          SMBRAW="$(
            echo "$NMAP_OUTPUT" \
              | awk '/SMB2_DIALECT_/ {print $NF}' \
              | sed 's/SMB2_DIALECT_//' \
              | tr -d '_' \
              | sort -V | tail -n 1 || true
          )"
          if [[ -z "$SMBRAW" ]] && echo "$NMAP_OUTPUT" | grep -Eiq 'NT LM 0\.12|SMBv1|NT1'; then
            SMB1_DETECTED=true
          fi
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

        if [[ -z "$SMBVERS" && "$SMB1_DETECTED" == "true" ]]; then
          echo "...... SMB version detected via nmap : SMBv1 (NT LM 0.12)"
          SMBVERS=",vers=1.0"
          SECVERS=",sec=ntlm"
        fi

        if [[ -n "$SMBVERS" ]]; then
          echo "...... SMB version detected : ${SMBVERS#,vers=}"
        elif command -v smbclient >/dev/null 2>&1 && smbclient -t 2 -L "$server" -m NT1 -U "$USERNAME%$PASSWORD" $DOMAINCLIENT -c "exit" &>/dev/null; then
          echo "...... SMB version : only SMBv1 is supported, this can lead to issues"
          SECVERS=",sec=ntlm"
          SMBVERS=",vers=1.0"
        else
          echo "...... SMB version : couldn't detect, falling back to SMB3->SMB2->SMB1 ladder on negotiation/dialect failure"
          SMBVERS=",vers=3.1.1"
        fi

        if [[ -n "$SMBVERS_FORCE" ]]; then
          if [[ -n "$SMBVERS" && "$SMBVERS" != "$SMBVERS_FORCE" ]]; then
            bashio::log.warning "...... overriding detected SMB version ${SMBVERS#,vers=} with forced ${SMBVERS_FORCE#,vers=} (server requires legacy protocol)"
          fi
          SMBVERS="$SMBVERS_FORCE"
          [[ -z "$SECVERS" ]] && SECVERS="$SECVERS_FORCE"
        fi

        SECVERS_BASE="$SECVERS"
        for SECTRY in "$SECVERS_BASE" ",sec=ntlmv2" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=krb5i" ",sec=krb5" ",sec=ntlm" ",sec=ntlmv2i"; do
          if [[ "$MOUNTED" == "false" ]]; then
            mount_drive "rw,file_mode=0775,dir_mode=0775,credentials=${CRED_FILE},nobrl,mfsymlinks${SMBVERS}${SECTRY}${PUID}${PGID}${CHARSET}"
          fi
        done

        if [[ "$MOUNTED" == "false" ]]; then
          retry_cifs_with_vers_ladder_on_dialect_failure
        fi

      else
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

    if [[ "$MOUNTED" == "true" ]]; then
      bashio::log.info "...... $disk successfully mounted to /mnt/$diskname with options ${MOUNTOPTIONS/$PASSWORD/XXXXXXXXXX}"
      rm -f "$ERRORCODE_FILE" 2>/dev/null || true

      if [[ "$FSTYPE" == "cifs" && "$MOUNTOPTIONS" == *"vers=1.0"* ]]; then
        bashio::log.warning ""
        bashio::log.warning "Your SMB system requires SMBv1. This is an obsolete protocol. Please correct this to prevent issues."
        bashio::log.warning ""
      fi

      cleanup_cred

    elif [[ "$MOUNTED" == "readonly" ]]; then
      bashio::log.warning "...... $disk mounted to /mnt/$diskname but is READ-ONLY or not writable by UID/GID ${PUID#,uid=}:${PGID#,gid=}."
      bashio::log.warning "...... Check Samba share permissions, or try setting PUID/PGID to 0/0 (root), or adjust server ACLs."
      rm -f "$ERRORCODE_FILE" 2>/dev/null || true
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

        mount_drive "rw,credentials=${CRED_FILE}${PUID}${PGID}"
        if [[ "$MOUNTED" == "false" ]]; then
          retry_cifs_with_vers_ladder_on_dialect_failure
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
