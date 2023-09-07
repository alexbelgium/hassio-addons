#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Runs only after initialization done
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

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

# Specify launcher
LAUNCHER="sudo -u abc php /app/www/public/occ"

# Only execute if installed
if [ -f /notinstalled ]; then exit 0; fi

# Check current version
if [ -f /data/config/www/nextcloud/config/config.php ]; then
    CURRENTVERSION="$(sed -n "s|.*version.*' => '*\(.*[^ ]\) *',.*|\1|p" /data/config/www/nextcloud/config/config.php)"
else
    CURRENTVERSION="Not found"
fi

# Updater apps code
if ! bashio::config.true "disable_updates"; then
    bashio::log.green "... checking for app updates"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ app:update --all"
else
    bashio::log.yellow "... disable_updates set, apps need to be updated manually"
fi

echo " "

# If not installed, or files not available
if [[ $($LAUNCHER -V 2>&1) == *"not installed"* ]] || [ ! -f /data/config/www/nextcloud/config/config.php ]; then
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.yellow "Nextcloud not installed, please wait for addon startup, login Webui, install Nextcloud, then restart the addon"
    bashio::log.green "--------------------------------------------------------------------------------------------------------------"
    bashio::log.green " "
    touch /notinstalled
    exit 0
    # Is there missing files
elif [[ $($LAUNCHER -V 2>&1) =~ ^"Nextcloud "[0-9].* ]]; then
    # Log
    bashio::log.green "----------------------------------------"
    bashio::log.green " Nextcloud $CURRENTVERSION is installed "
    bashio::log.green "----------------------------------------"
    # Tentative to downgrade
else
    bashio::log.red "-------------------------------------------------"
    bashio::log.red " Unknown error detected, auto-repair will launch "
    bashio::log.red "-------------------------------------------------"
    bashio::log.red "Error message:"
    bashio::log.red "$($LAUNCHER -V 2>&1)"
    bashio::log.red "------------------------------------------------------------------"
    bashio::exit.nok
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair"
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair-share-owner"
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ upgrade"
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:mode --off"
fi

echo " "


###########################
# DISABLE MAINTENACE MODE #
###########################

echo "... Clean potential errors"
sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair" >/dev/null || true
sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:repair-share-owner" >/dev/null || true
sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ maintenance:mode --off"

##############
# CLEAN OCDE #
##############

echo "... Remove OCDE if installed as not compatible"
sudo -u abc php /app/www/public/occ app:remove --no-interaction "richdocumentscode" &>/dev/null || true
sudo -u abc php /app/www/public/occ app:remove --no-interaction "richdocumentscode_arm64" &>/dev/null || true
sudo -u abc php /app/www/public/occ app:remove --no-interaction "richdocumentscode_amd64" &>/dev/null || true

################
# DEFINE PHONE #
################

if bashio::config.has_value "default_phone_region"; then
    echo "... Define default_phone_region"
    sudo -u abc php /app/www/public/occ config:system:set default_phone_region --value="$(bashio::config "default_phone_region")"
fi

######################
# Modify config.json #
######################

echo "... Disabling check_data_directory_permissions"
for files in /defaults/config.php /data/config/www/nextcloud/config/config.php; do
    if [ -f "$files" ]; then
        sed -i "/check_data_directory_permissions/d" "$files"
        sed -i "/datadirectory/a 'check_data_directory_permissions' => false," "$files"
    fi
done
timeout 10 sudo -u abc php /app/www/public/occ config:system:set check_data_directory_permissions --value=false --type=bool || echo "Please install nextcloud first"
