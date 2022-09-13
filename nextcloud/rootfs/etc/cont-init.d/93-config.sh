#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#create folders
echo "Creating folders"
datadirectory=$(bashio::config 'data_directory')
mkdir -p \
    "$datadirectory" \
    /data/config/nextcloud/config \
    /data/config/nextcloud/data \
    /data/config/www/nextcloud/config

#permissions
PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"
chown -R "$PUID":"$PGID" \
    "$datadirectory" \
    /data/config/nextcloud/config \
    /data/config/nextcloud/data \
    /data/config/www/nextcloud/config \
    /data

chown -R abc:abc \
    /var/lib/nginx

rm -r /data/config/www/nextcloud/assets &>/dev/null || true

echo "Updating permissions"
chmod -R 770 /data/config
chmod -R 770 "$datadirectory"

#Prevent permissions check
for files in /defaults/config.php /data/config/www/nextcloud/config/config.php; do
if [ -f "$files" ]; then
sed -i "/check_data_directory_permissions/d" "$files"
sed -i "/datadirectory/a 'check_data_directory_permissions' => false," "$files"
fi
done
