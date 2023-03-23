#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

####################################
# Clean nginx files at each reboot #
####################################

echo "Cleaning files"
for var in /data/config/nginx /data/config/crontabs /data/config/logs; do
    if [ -d "$var" ]; then rm -r "$var"; fi
done

######################################
# Make links between logs and docker #
######################################

echo "Setting logs"
for var in /data/config/log/nginx/error.log /data/config/log/nginx/access.log /data/config/log/php/error.log; do
    # Make sure directory exists
    mkdir -p "$(dirname "$var")"
    # Clean files
    if [ -f "$var" ]; then rm -r "$var"; fi
    # Create symlink
    ln -sf /proc/1/fd/1 "$var"
done

######################
# REINSTALL IF ISSUE #
######################

echo "Checking installation"
if [[ "$(occ --version)" == *"Composer autoloader not found"* ]]; then
    bashio::log.fatal "Issue with installation detected, reinstallation will proceed"
    bashio::log.fatal "-------------------------------------------------------------."
    bashio::log.fatal " "

    # Check currently installed version
    if [ -f /data/config/www/nextcloud/version.php]; then
        CURRENTVERSION="$(sed -n "s|.*\OC_VersionString = '*\(.*[^ ]\) *';.*|\1|p" /data/config/www/nextcloud/version.php)"
    else
        if [ -d /data/config/www/nextcloud ]; then rm -r /data/config/www/nextcloud; fi
        CURRENTVERSION="$(cat /nextcloudversion)"
    fi

    # Redownload nextcloud if wrong version
    if [[ ! "$CURRENTVERSION" == "$(cat /nextcloudversion)" ]]; then
        bashio::log.fatal "Version installed is : $CURRENTVERSION and version bundled is : $ADDONVERSION, need to redownload files"
        bashio::log.fatal "... download nextcloud version"
        rm /app/nextcloud.tar.bz2
        curl -o /app/nextcloud.tar.bz2 -L https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_RELEASE}.tar.bz2
    fi

    bashio::log.fatal "Reinstall ongoing, please wait..."
    rm /data/config/www/nextcloud/index.php
    /./etc/s6-overlay/s6-rc.d/init-nextcloud-config/run
    bashio::log.fatal "... done"
fi
