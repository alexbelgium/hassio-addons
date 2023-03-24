#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

####################################
# Clean nginx files at each reboot #
####################################

echo "Cleaning files"
for var in /data/config/nginx /data/config/crontabs /data/config/logs; do
    if [ -d "$var" ]; then rm -r "$var"; fi
done

######################
# REINSTALL IF ISSUE #
######################

echo "Checking installation"
(if [[ "$(occ -V)" == *"Composer autoloader not found"* ]]; then
  touch /reinstall
fi) &> /dev/null

# Check currently installed version
if [ -f /data/config/www/nextcloud/version.php ]; then
    CURRENTVERSION="$(sed -n "s|.*\OC_VersionString = '*\(.*[^ ]\) *';.*|\1|p" /data/config/www/nextcloud/version.php)"
else
    if [ -d /data/config/www/nextcloud ]; then rm -r /data/config/www/nextcloud; fi
    CURRENTVERSION="$(cat /nextcloudversion)"
fi

# Reinstall if needed
if [ -f /reinstall ]; then
    rm /reinstall
    bashio::log.fatal "Issue with installation detected, reinstallation will proceed"
    bashio::log.fatal "-------------------------------------------------------------."
    bashio::log.fatal " "

    # Redownload nextcloud if wrong version
    if [[ ! "$CURRENTVERSION" == "$(cat /nextcloudversion)" ]]; then
        basio::log.fatal "Version installed is : $CURRENTVERSION and version bundled is : $ADDONVERSION, need to redownload files"
        bashio::log.fatal "... download nextcloud version"
        rm /app/nextcloud.tar.bz2
        curl -o /app/nextcloud.tar.bz2 -L "https://download.nextcloud.com/server/releases/nextcloud-${CURRENTVERSION}.tar.bz2" --progress-bar || \
        (bashio::log.fatal "Your version doesn't exist... Please restore backup or fully uninstall addon" && exit 1)
    fi

    bashio::log.fatal "Reinstall ongoing, please wait..."
    rm /data/config/www/nextcloud/index.php
    /./etc/s6-overlay/s6-rc.d/init-nextcloud-config/run
    bashio::log.fatal "... done"

else
    function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
    if [ "$(version "$(cat /nextcloudversion)")" -ge "$(version "$CURRENTVERSION")" ]; then
        bashio::log.warning "Nexctloud $CURRENTVERSION is installed but $(cat /nextcloudversion) is in this container"
        if bashio::config.true 'auto_updater'; then
            bashio::log.warning "auto_updater configured, update starts now"
            updater.phar
        else
            bashio::log.warning "auto_updater not set in addon options, please update from nextcloud settings"
        fi
    fi || true
fi

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
