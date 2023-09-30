#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured
if bashio::config.has_value 'localdisks'; then

    # Install lsblk
    if ! command -v "lsblk" &>/dev/null; then
        if command -v "apk" &>/dev/null; then apk add --no-cache lsblk >/dev/null; fi
        if command -v "apt" &>/dev/null; then apt-get update && apt-get install -yqq util-linux; fi
    fi

    ## List available Disk with Labels and Id
    bashio::log.blue "---------------------------------------------------"
    bashio::log.info "Available Disks :"
    lsblk -o name,label,size,fstype,type,ro | awk '$5 != "" { print $0 }'
    bashio::log.blue "---------------------------------------------------"

    MOREDISKS=$(bashio::config 'localdisks')
    echo "Local Disks mounting..."

    # Separate comma separated values
    # shellcheck disable=SC2086
    for disk in ${MOREDISKS//,/ }; do

        # Mount by device as default
        devpath=/dev

        # Mount as uuid
        if [ ${#disk} == 36 ] ; then
            devpath=/dev/disk/by-uuid
            # Mount as label
        elif [ "${disk:0:2}" != "sd" ] && [ "${disk:0:4}" != "nvme" ] ; then
            devpath=/dev/disk/by-label
        fi

        # Creates dir
        mkdir -p /mnt/"$disk"
        if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
            PUID="$(bashio::config 'PUID')"
            PGID="$(bashio::config 'PGID')"
            chown "$PUID:$PGID" /mnt/"$disk"
        fi

        # Check FS type and set relative options (thanks @https://github.com/dianlight/hassio-addons)
        fstype=$(lsblk "$devpath"/"$disk" -no fstype)
        options="nosuid,relatime,noexec"
        type="auto"
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
        mount -t $type "$devpath"/"$disk" "$dirpath"/"$disk" -o $options && bashio::log.info "Success! $disk mounted to /mnt/$disk" || \
            (bashio::log.fatal "Unable to mount local drives! Please check the name."
            rmdir /mnt/"$disk"
        bashio::addon.stop)
    done

fi
