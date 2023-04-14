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

# Updater code
if ! bashio::config.true "disable_updates"; then
    bashio::log.green "Auto_updater set, checking for updates"
    # Install new version
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/updater/updater.phar --no-interaction"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ upgrade"
    sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ app:update --all"
    # Install additional versions
    while [[ $(occ update:check 2>&1) == *"update available"* ]]; do
        bashio::log.yellow "-----------------------------------------------------------------------"
        bashio::log.yellow "  new version available, updating. Please do not turn off your addon!  "
        bashio::log.yellow "-----------------------------------------------------------------------"
        sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/updater/updater.phar --no-interaction"
        sudo -u abc -s /bin/bash -c "php /data/config/www/nextcloud/occ upgrade"
    done
    # Reset permissions
    /./etc/cont-init.d/01-folders.sh
elif bashio::config.true "disable_updates" && [ "$(version "$CONTAINERVERSION")" -gt "$(version "$CURRENTVERSION")" ]; then
    bashio::log.yellow " "
    bashio::log.yellow "New version available : $CONTAINERVERSION"
    bashio::log.yellow "...auto_updater not set in addon options, please update from nextcloud settings"
fi
