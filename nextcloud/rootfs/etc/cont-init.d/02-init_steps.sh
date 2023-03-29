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

# Get launcher
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
    # Is there an error
elif [[ $($LAUNCHER -V 2>&1) == *"Composer autoloader not found"* ]]; then
    bashio::log.red "--------------------------------------------------------"
    bashio::log.red "Issue in installation detected, Nextcloud will reinstall"
    bashio::log.red "--------------------------------------------------------"
    touch /reinstall
elif [[ $($LAUNCHER -V 2>&1) == *"Nextcloud"* ]] || grep -q "/mnt/" /data/config/www/nextcloud/config/config.php &>/dev/null; then
    # Log
    bashio::log.green "--------------------------------------"
    bashio::log.green "Nextcloud $CURRENTVERSION is installed"
    bashio::log.green "--------------------------------------"
elif ! grep -q "/mnt/" /data/config/www/nextcloud/config/config.php; then
    bashio::log.red "------------------------------------------------------------------"
    bashio::log.red "Unknown error detected, please create issue in github or reinstall"
    bashio::log.red "------------------------------------------------------------------"
    bashio::log.red "Error message:"
    bashio::log.red "$($LAUNCHER -V 2>&1)"
    bashio::log.red "------------------------------------------------------------------"
    bashio::exit.nok
fi

echo " "

######################
# REINSTALL IF ISSUE #
######################

# Reinstall if needed
if [ -f /reinstall ]; then
    rm /reinstall
    bashio::log.red "... issue with installation detected, reinstallation will proceed"

    # Redownload nextcloud if wrong version
    if [[ ! "$CURRENTVERSION" == "$CONTAINERVERSION" ]]; then
        bashio::log.red "... version installed is : $CURRENTVERSION and version bundled is : $CONTAINERVERSION, need to redownload files"
        bashio::log.green "... download nextcloud version"
        nextcloud_download "nextcloud-${CURRENTVERSION}" || (bashio::log.fatal "Your version doesn't exist... Please restore backup or fully uninstall addon" && exit 1)
    fi

    # Reinstall
    bashio::log.green "... reinstall ongoing, please wait"
    if [ -f /data/config/www/nextcloud/index.php ]; then rm /data/config/www/nextcloud/index.php; fi && \
        /./etc/s6-overlay/s6-rc.d/init-nextcloud-config/run
        occ upgrade &>/proc/1/fd/1 || true
fi

#####################
# RESET PERMISSIONS #
#####################

PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")
datadirectory=$(bashio::config 'data_directory')

echo "Checking permissions"
mkdir -p /data/config
mkdir -p "$datadirectory"
chmod 755 -R "$datadirectory"
chmod 755 -R /data/config
chown -R "$PUID:$PGID" "$datadirectory"
chown -R "$PUID:$PGID" "/data/config"
