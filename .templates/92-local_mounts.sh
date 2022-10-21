#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured
if bashio::config.has_value 'localdisks'; then

    MOREDISKS=$(bashio::config 'localdisks')
    echo "Local Disks mounting..."

    # Mount using UID/GID values
    if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID' && [ -z ${ROOTMOUNT+x} ]; then
        echo "Using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
        PUID="$(bashio::config 'PUID')"
        PGID="$(bashio::config 'PGID')"
    else
        PUID="0"
        PGID="0"
    fi

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
        chown "$PUID:$PGID" /mnt/"$disk"
        # Legacy mounting : mount to share if still exists (avoid breaking changes)
        # shellcheck disable=SC2015
        [ -d /share/"$disk" ] && mount "$devpath"/"$disk" /share/"$disk" || true
        # Mount
        # shellcheck disable=SC2015
        mount "$devpath"/"$disk" -o "uid=$PUID,gid=$PGID" /mnt/"$disk" && bashio::log.info "Success! $disk mounted to /mnt/$disk" || \
        mount "$devpath"/"$disk" /mnt/"$disk" && bashio::log.info "Success! $disk mounted to /mnt/$disk" && bashio::log.info "Success! $disk mounted to /mnt/$disk" || (bashio::log.fatal "Unable to mount local drives! Please check the name." && rmdir /mnt/$disk)

    done

fi
