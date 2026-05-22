#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if ! bashio::supervisor.ping 2> /dev/null; then
    echo "..."
    exit 0
fi

bashio::log.notice "This script is used to mount local USB/SATA/SD/NVMe drives. Instructions here : https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons"

# Available devices
blkid | awk '{print substr($1, 0, length($1) - 1)}' | awk -F'/' '{print $NF}' > availabledisks
echo "NAME" >> availabledisks

## List available Disk with Labels and Id
bashio::log.blue "---------------------------------------------------"
bashio::log.info "Available Disks for mounting :"
lsblk -o name,label,size,fstype,ro | awk '$4 != "" { print $0 }' | grep -f availabledisks
bashio::log.blue "---------------------------------------------------"
rm availabledisks

# Show support fs https://github.com/dianlight/hassio-addons/blob/2e903184254617ac2484fe7c03a6e33e6987151c/sambanas/rootfs/etc/s6-overlay/s6-rc.d/init-automount/run#L106
fstypessupport=$(grep -v nodev < /proc/filesystems | awk '{$1=" "$1}1' | tr -d '\n\t')
bashio::log.green "Supported fs : ${fstypessupport}"
bashio::log.green "Inspired from : github.com/dianlight"
bashio::log.blue "---------------------------------------------------"

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured
if bashio::config.has_value 'localdisks'; then

    MOREDISKS=$(bashio::config 'localdisks')
    echo "Local Disks mounting..."

    # Separate comma separated values
    # shellcheck disable=SC2086
    for disk in ${MOREDISKS//,/ }; do

        # Remove text until last slash
        disk="${disk##*/}"

        # Function to check what is the type of device
        if [ -e /dev/"$disk" ]; then
            echo "... $disk is a physical device"
            devpath=/dev
        elif [ -e /dev/disk/by-uuid/"$disk" ] || lsblk -o UUID | grep -q "$disk"; then
            echo "... $disk is a device by UUID"
            devpath=/dev/disk/by-uuid
        elif [ -e /dev/disk/by-label/"$disk" ] || lsblk -o LABEL | grep -q "$disk"; then
            echo "... $disk is a device by label"
            devpath=/dev/disk/by-label
        else
            bashio::log.fatal "$disk does not match any known physical device, UUID, or label. "
            continue
        fi

        # Creates dir
        mkdir -p /mnt/"$disk"

        # Check FS type and set relative options (thanks @https://github.com/dianlight/hassio-addons)
        fstype=$(lsblk "$devpath"/"$disk" -no fstype)
        options="nosuid,relatime,noexec"
        type="auto"

        # Check if supported
        if [[ "${fstypessupport}" != *"${fstype}"* ]]; then
            bashio::log.fatal : "${fstype} type for ${disk} is not supported"
            break
        fi

        # Mount drive
        bashio::log.info "Mounting ${disk} of type ${fstype}"
        case "$fstype" in
            exfat | vfat | msdos)
                bashio::log.warning "${fstype} permissions and ACL don't works and this is an EXPERIMENTAL support"
                options="${options},umask=000"
                ;;
            ntfs)
                bashio::log.warning "${fstype} is an EXPERIMENTAL support"
                options="${options},umask=000"
                type="ntfs"
                ;;
            squashfs)
                bashio::log.warning "${fstype} is an EXPERIMENTAL support"
                options="loop"
                type="squashfs"
                ;;
        esac

        # Legacy mounting : mount to share if still exists (avoid breaking changes)
        dirpath="/mnt"
        if [ -d /share/"$disk" ]; then dirpath="/share"; fi

        # shellcheck disable=SC2015
        mount -t $type "$devpath"/"$disk" "$dirpath"/"$disk" -o $options && bashio::log.info "Success! $disk mounted to $dirpath/$disk" \
            || (
                bashio::log.fatal "Unable to mount local drives! Please check the name."
                rmdir /mnt/"$disk"
                bashio::addon.stop
            )

        # Check if the mount is accessible by the configured PUID/PGID
        # We do NOT chown/chmod the mount point as that would modify actual disk permissions
        if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
            PUID="$(bashio::config 'PUID')"
            mount_owner=$(stat -c '%u' "$dirpath/$disk" 2>/dev/null)
            mount_perms=$(stat -c '%a' "$dirpath/$disk" 2>/dev/null)
            if [ "$mount_owner" != "$PUID" ] && [ "${mount_perms:2:1}" = "0" ]; then
                bashio::log.warning "$dirpath/$disk is owned by UID $mount_owner with permissions $mount_perms - may not be accessible by PUID $PUID."
                bashio::log.warning "If the drive appears empty, fix permissions on the drive root: chmod 755 <mountpoint> (on the host)."
            fi
        fi
    done

fi
