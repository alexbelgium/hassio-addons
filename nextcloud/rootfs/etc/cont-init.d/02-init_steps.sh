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

###########################
# CHECK INSTALLED VERSION #
###########################

# Check currently installed version
CONTAINERVERSION="$(cat /nextcloudversion)"
if [ -f /data/config/www/nextcloud/version.php ]; then
    CURRENTVERSION="$(sed -n "s|.*\OC_VersionString = '*\(.*[^ ]\) *';.*|\1|p" /data/config/www/nextcloud/version.php)"
    bashio::log.green "--------------------------------------"
    bashio::log.green "Nextcloud $CURRENTVERSION is installed"
    bashio::log.green "--------------------------------------"
else
    if [ -d /data/config/www/nextcloud ]; then rm -r /data/config/www/nextcloud; fi
    CURRENTVERSION="$CONTAINERVERSION"
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.yellow "Nextcloud not installed, please wait for addon startup, login Webui, install Nextcloud, then restart the addon"
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.green " "
    exit 0
fi

#########################
# INFORM IF NEW VERSION #
#########################

# Inform if new version available
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
if [ "$(version "$CONTAINERVERSION")" -gt "$(version "$CURRENTVERSION")" ]; then
    bashio::log.yellow " "
    bashio::log.yellow "New version available : $CONTAINERVERSION"
    if bashio::config.true 'auto_updater'; then
        if [[ $((CONTAINERVERSION-CURRENTVERSION)) = 1 ]]; then echo "nok"; fi
        bashio::log.green "... auto_updater configured, update starts now"
        updater.phar &>/proc/1/fd/1
    else
        bashio::log.yellow "...auto_updater not set in addon options, please update from nextcloud settings"
    fi
fi

######################
# REINSTALL IF ISSUE #
######################

# Check if issue in installation
bashio::log.green "Checking installation"
( if [[ "$(occ -V 2>&1)" == *"Composer autoloader not found"* ]]; then
  touch /reinstall
fi ) &> /dev/null

# Reinstall if needed
if [ -f /reinstall ]; then
    rm /reinstall
    bashio::log.red "... issue with installation detected, reinstallation will proceed"

    # Redownload nextcloud if wrong version
    if [[ ! "$CURRENTVERSION" == "$CONTAINERVERSION" ]]; then
        basio::log.red "... version installed is : $CURRENTVERSION and version bundled is : $CONTAINERVERSION, need to redownload files"
        bashio::log.green "... download nextcloud version"
        rm /app/nextcloud.tar.bz2
        curl -o /app/nextcloud.tar.bz2 -L "https://download.nextcloud.com/server/releases/nextcloud-${CURRENTVERSION}.tar.bz2" --progress-bar || \
        (bashio::log.fatal "Your version doesn't exist... Please restore backup or fully uninstall addon" && exit 1)
    fi

    # Reinstall
    bashio::log.green "... reinstall ongoing, please wait"
    rm /data/config/www/nextcloud/index.php && \
    /./etc/s6-overlay/s6-rc.d/init-nextcloud-config/run

fi

bashio::log.green "... done"
