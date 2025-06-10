#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
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
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair" || true
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair-share-owner" || true
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ app:update --all" || true
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ upgrade" || true
fi

echo " "

####################
# UPDATER APP CODE #
####################

# Updater apps code
if ! bashio::config.true "disable_updates"; then
    bashio::log.green "... checking for app updates"
    sudo -u abc -s /bin/bash -c "php /app/www/public/occ app:update --all" || true
else
    bashio::log.yellow "... disable_updates set, apps need to be updated manually"
fi

###########################
# DISABLE MAINTENACE MODE #
###########################

echo "... Clean potential errors"
sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair" > /dev/null || true
sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:repair-share-owner" > /dev/null || true
sudo -u abc -s /bin/bash -c "php /app/www/public/occ maintenance:mode --off" || true

##############
# CLEAN OCDE #
##############

echo "... Remove CODE if installed as not compatible"

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
        sed -i "/datadirectory/a\ \ 'check_data_directory_permissions' => false," "$files"
  fi
done
timeout 10 sudo -u abc php /app/www/public/occ config:system:set check_data_directory_permissions --value=false --type=bool || echo "Please install nextcloud first"

##################
# Modify php.ini #
##################

for variable in env_memory_limit env_upload_max_filesize env_post_max_size; do
    if bashio::config.has_value "$variable"; then
        variable="${variable#env_}"
        sed -i "/$variable/c $variable = $(bashio::config "env_$variable")" /etc/php*/conf.d/nextcloud.ini
        sed -i "/$variable/c $variable = $(bashio::config "env_$variable")" /etc/php*/php.ini
        bashio::log.blue "$variable set to $(bashio::config "env_$variable")"
  fi
done

#####################
# Enable thumbnails #
#####################

if bashio::config.true "enable_thumbnails"; then
    echo "... enabling thumbnails"
    # Add variables
    sudo -u abc php /app/www/public/occ config:system:set preview_ffmpeg_path --value='/usr/bin/ffmpeg'
    sudo -u abc php /app/www/public/occ config:system:set enable_previews --value=true
    i=0
    for element in AVI BMP Font GIF HEIC Image JPEG Krita MarkDown MKV Movie MP3 MP4 OpenDocument PDF PNG SVG TIFF TXT XBitmap; do # Comma separated values
        sudo -u abc php /app/www/public/occ config:system:set enabledPreviewProviders "$i" --value="OC\\Preview\\${element}" > /dev/null
        i=$((i + 1))
  done
else
    # Remove variables
    echo "... disabling thumbnails"
    sudo -u abc php /app/www/public/occ config:system:set enable_previews --value=false
fi

##########################
# Set maintenance period #
##########################

if [[ "$(occ config:system:get maintenance_window_start)" == "" ]]; then
    echo "... maintenance windows not set, it will be changed to 1"
    sudo -u abc php /app/www/public/occ config:system:set maintenance_window_start --type=integer --value=1
fi
