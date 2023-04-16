#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if bashio::config.has_value "PUID" && bashio::config.has_value "PGID"; then
    PUID="$(bashio::config "PUID")"
    PGID="$(bashio::config "PGID")"
    bashio::log.green "Setting user to $PUID:$PGID"
    id -u abc &>/dev/null || usermod -o -u "$PUID" abc || true
    id -g abc &>/dev/null || groupmod -o -g "$PGID" abc || true
fi

echo "Updating permissions..."
echo "... Config directory : /data"
mkdir -p /data/config
chmod 755 -R /data/config
chown -R "$PUID:$PGID" "/data/config"

# Check current version
if [ -f /data/config/www/nextcloud/config/config.php ]; then
    datadirectory="$(sed -n "s|.*datadirectory.*' => '*\(.*[^ ]\) *',.*|\1|p" /data/config/www/nextcloud/config/config.php)"
    echo "... Data directory detected : $datadirectory"
else
    datadirectory=/share/nextcloud
    echo "Nextcloud is not installed yet, the default data directory is : $datadirectory. You can change it during nextcloud installation."
fi

# Is the directory valid
if [[ "$datadirectory" == *"/mnt/"* ]] && [ ! -f "$datadirectory"/index.html ]; then
    bashio::log.fatal "Data directory does not seem to be valid. Is your drive connected? Stopping to avoid corrupting the data directory."
    bashio::addon.stop
fi

mkdir -p "$datadirectory"
chmod 755 -R "$datadirectory"
chown -R "$PUID:$PGID" "$datadirectory"

######################
# Modify config.json #
######################

for files in /defaults/config.php /data/config/www/nextcloud/config/config.php; do
    if [ -f "$files" ]; then
        sed -i "/check_data_directory_permissions/d" "$files"
        sed -i "/datadirectory/a 'check_data_directory_permissions' => false," "$files"
    fi
done
sudo -u abc php /data/config/www/nextcloud/occ config:system:set check_data_directory_permissions --value=false --type=bool || echo "Please install nextcloud first"

echo "...done"
echo " "
