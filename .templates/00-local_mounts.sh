#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###############################################################################
# Strong defaults                                                             #
###############################################################################
set -Eeuo pipefail
shopt -s inherit_errexit

trap 'bashio::log.fatal "Line ${LINENO}: command «${BASH_COMMAND}» failed"; exit 1' ERR

###############################################################################
# Helpers                                                                     #
###############################################################################

log()  { bashio::log.green   "$*"; }
warn() { bashio::log.yellow  "$*"; }
die()  { bashio::log.fatal   "$*"; }

# Return first existing path for $1 (device name, UUID, or LABEL), else 1.
resolve_device() {
    local d="$1"
    for p in "/dev/${d}" \
             "/dev/disk/by-uuid/${d}" \
             "/dev/disk/by-label/${d}" ; do
        [[ -e $p ]] && { echo "$p"; return 0; }
    done
    return 1
}

safe_mount() {                     # safe_mount SRC MNT FSTYPE OPTS
    local src=$1 mnt=$2 fstype=$3 opts=$4

    # Already mounted?
    if findmnt -rn --source "$src" --target "$mnt" &>/dev/null; then
        warn "$src is already mounted on $mnt – skipping"
        return 0
    fi

    bashio::log.blue "→ mount -t ${fstype} -o ${opts} ${src} ${mnt}"
    mount -t "$fstype" -o "$opts" "$src" "$mnt"
}

supported_fs() {
    grep -v nodev /proc/filesystems | awk '{print $1}'
}

###############################################################################
# Early exit if supervisor not present (addon start during build, etc.)       #
###############################################################################
if ! bashio::supervisor.ping &>/dev/null; then
    log "Supervisor not reachable – nothing to mount"
    exit 0
fi

###############################################################################
# Disk discovery & presentation                                               #
###############################################################################
if ! bashio::config.has_value 'localdisks'; then
    log "No «localdisks» option – skipping local mounts"
    exit 0
fi

mapfile -t SUPPORTED < <(supported_fs)
declare -A FS_OK
for f in "${SUPPORTED[@]}"; do FS_OK["$f"]=1; done

bashio::log.blue "---------------------------------------------------"
log  "Supported filesystems : ${SUPPORTED[*]}"
bashio::log.blue "---------------------------------------------------"
log  "Available block devices:"
lsblk -o NAME,LABEL,UUID,SIZE,FSTYPE,RO
bashio::log.blue "---------------------------------------------------"

###############################################################################
# Main loop                                                                   #
###############################################################################
IFS=',' read -ra DISKS <<< "$(bashio::config 'localdisks')"

for raw in "${DISKS[@]}"; do
    disk="${raw##*/}"                      # strip /path/ if user pasted one
    dev=$(resolve_device "$disk") || { warn "${disk}: no matching device"; continue; }

    fstype=$(lsblk -no FSTYPE "$dev")
    [[ -z $fstype ]] && { warn "${disk}: could not detect filesystem"; continue; }

    if [[ -z ${FS_OK["$fstype"]+1} ]]; then
        warn "${disk}: filesystem ${fstype} not supported by kernel – skipping"
        continue
    fi

    # Default options
    opts="nosuid,relatime,noexec"
    type="$fstype"

    case "$fstype" in
        exfat|vfat|msdos)
            warn "${fstype}: experimental support – ACLs not honoured"
            opts+=",umask=000"
            ;;
        ntfs)
            warn "NTFS: experimental support"
            opts+=",umask=000"
            type="ntfs"        # for ntfs-3g
            ;;
        squashfs)
            warn "squashfs is read-only; mounting with loop"
            opts="loop"
            ;;
    esac

    mnt="/mnt/${disk}"
    mkdir -p "$mnt"
    if mountpoint -q "$mnt"; then umount "$mnt"; fi

    if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
        chown "$(bashio::config 'PUID'):$(bashio::config 'PGID')" "$mnt"
    fi

    if safe_mount "$dev" "$mnt" "$type" "$opts"; then
        log "Mounted ${disk} on ${mnt}"
    else
        die "Failed to mount ${disk}"
    fi
done
