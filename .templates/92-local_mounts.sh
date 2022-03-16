#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

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

        # Mount by device as default
        devpath=/dev

        # Mount as label
        [ "${disk:0:2}" != "sd" ] && devpath=/dev/disk/by-label

        # Creates dir
        mkdir -p /mnt/"$disk"
        chown -R "$(id -u)":"$(id -g)" /mnt/"$disk"
        # Legacy mounting : mount to share if still exists (avoid breaking changes)
        # shellcheck disable=SC2015
        [ -d /share/"$disk" ] && mount "$devpath"/"$disk" /share/"$disk" || true
        # Mount
        # shellcheck disable=SC2015
        mount "$devpath"/"$disk" /mnt/"$disk" && bashio::log.info "Success! $disk mounted to /mnt/$disk" || (bashio::log.fatal "Unable to mount local drives! Please check the name." && rmdir /mnt/$disk)

    done

fi
