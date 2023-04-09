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

################
# CHECK STATUS #
################

# Clean remnant files
if [ -f /notinstalled ]; then
    rm /notinstalled
fi

# Specify launcher
LAUNCHER="sudo -u abc php /data/config/www/nextcloud/occ"

# Check current version
if [ -f /data/config/www/nextcloud/version.php ]; then
    CURRENTVERSION="$(sed -n "s|.*\OC_VersionString = '*\(.*[^ ]\) *';.*|\1|p" /data/config/www/nextcloud/version.php)"
else
    CURRENTVERSION="Not found"
fi

echo " "

# If not installed, or files not available
if [[ $($LAUNCHER -V 2>&1) == *"not installed"* ]] || [ ! -f /data/config/www/nextcloud/version.php ]; then
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.yellow "Nextcloud not installed, please wait for addon startup, login Webui, install Nextcloud, then restart the addon"
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.green " "
    touch /notinstalled
    exit 0
    # Is there missing files
elif [[ $($LAUNCHER -V 2>&1) == *"Composer autoloader not found"* ]] || [[ $($LAUNCHER -V 2>&1) == *"No such file"* ]] ; then
    bashio::log.red "--------------------------------------------------"
    bashio::log.red " Missing files detected, Nextcloud will reinstall "
    bashio::log.red "--------------------------------------------------"
    touch /reinstall
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair-share-owner"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ upgrade"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:mode --off"
    # Everything is fine
elif [[ $($LAUNCHER -V 2>&1) =~ ^"Nextcloud "[0-9].* ]]; then
    # Log
    bashio::log.green "----------------------------------------"
    bashio::log.green " Nextcloud $CURRENTVERSION is installed "
    bashio::log.green "----------------------------------------"
    # Tentative to downgrade
elif [[ $($LAUNCHER -V 2>&1) == *"Downgrading"* ]]; then
    # Get currently installed version
    version="$($LAUNCHER -V 2>&1)"
    version="${version% to *}"
    version="${version#*from }"
    until [ "$(echo "$version" | awk -F. '{ print NF - 1 }')" -le "2" ]; do
        version="${version%\.*}"
    done
    # Inform
    bashio::log.red "-----------------------------------------------------------------------------------------------------"
    bashio::log.red " Error : a downgrade was detected. This is not possible. The current version $version will reinstall "
    bashio::log.red "-----------------------------------------------------------------------------------------------------"
    # Reinstall current version
    CURRENTVERSION="$version"
    touch /reinstall
else
    bashio::log.red "-------------------------------------------------"
    bashio::log.red " Unknown error detected, auto-repair will launch "
    bashio::log.red "-------------------------------------------------"
    bashio::log.red "Error message:"
    bashio::log.red "$($LAUNCHER -V 2>&1)"
    bashio::log.red "------------------------------------------------------------------"
    bashio::exit.nok
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair-share-owner"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ upgrade"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:mode --off"
fi

echo " "

######################
# REINSTALL IF ISSUE #
######################

# Reinstall if needed
if [ -f /reinstall ]; then
    rm /reinstall
    bashio::log.red "... issue with installation detected, reinstallation will proceed"

    # Check container version
    CONTAINERVERSION="$(cat /nextcloudversion)"

    # Downloader function
    function nextcloud_download {
        mkdir -p /app
        if [ -f /app/nextcloud.tar.bz2 ]; then rm /app/nextcloud.tar.bz2; fi
        curl -s -o /app/nextcloud.tar.bz2 -L "https://download.nextcloud.com/server/releases/$1.tar.bz2"
    }

    # Redownload nextcloud if wrong version
    if [[ ! "$CURRENTVERSION" == "$CONTAINERVERSION" ]]; then
        bashio::log.red "... version installed is : $CURRENTVERSION and version bundled is : $CONTAINERVERSION, need to redownload files"
        bashio::log.green "... download nextcloud version"
        nextcloud_download "nextcloud-${CURRENTVERSION}" || (bashio::log.fatal "Your version doesn't exist... Please restore backup or fully uninstall addon" && exit 1)
    fi

    # Reinstall
    bashio::log.green "... reinstall ongoing, please wait"
    if [ -f /data/config/www/nextcloud/index.php ]; then rm /data/config/www/nextcloud/index.php; fi && \
        # INSTALL
    /./etc/s6-overlay/s6-rc.d/init-nextcloud-config/run
    # RESET PERMISSIONS
    /./etc/cont-init.d/01-folders.sh
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair-share-owner"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ upgrade"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:mode --off"
fi
