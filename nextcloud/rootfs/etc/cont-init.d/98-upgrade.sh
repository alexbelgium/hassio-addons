#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Only execute if installed
if [ -f /notinstalled ]; then exit 0; fi

# Check current version
if [ -f /data/config/www/nextcloud/version.php ]; then
    CURRENTVERSION="$(sed -n "s|.*\OC_VersionString = '*\(.*[^ ]\) *';.*|\1|p" /data/config/www/nextcloud/version.php)"
else
    CURRENTVERSION="Not found"
fi
# Check container version
CONTAINERVERSION="$(cat /nextcloudversion)"

# Inform if new version available
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
# Inform if new version available
function nextcloud_download { 
    mkdir -p /app
    if [ -f /app/nextcloud.tar.bz2 ]; then rm /app/nextcloud.tar.bz2; fi
    curl -o /app/nextcloud.tar.bz2 -L "https://download.nextcloud.com/server/releases/$1.tar.bz2"
    } 

# Updater code
if bashio::config.true 'auto_updater'; then
    bashio::log.green "Auto_updater set, checking for updates"
    while [[ $(occ update:check 2>&1) == *"update available"* ]]; do
        bashio::log.yellow "-----------------------------------------------------------------------"
        bashio::log.yellow "  new version available, updating. Please do not turn off your addon!  "
        bashio::log.yellow "-----------------------------------------------------------------------"
        updater.phar --no-interaction
        occ upgrade
    done
elif [ "$(version "$CONTAINERVERSION")" -gt "$(version "$CURRENTVERSION")" ]; then
    bashio::log.yellow " "
    bashio::log.yellow "New version available : $CONTAINERVERSION"
    bashio::log.yellow "...auto_updater not set in addon options, please update from nextcloud settings"
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
