#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

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
    echo "... data directory detected : $datadirectory"
else
    datadirectory=/config/data
    echo "Nextcloud is not installed yet, the default data directory is : $datadirectory. You can change it during nextcloud installation."
    mkdir -p /config/data
    chmod 777 /config/data
    mkdir -p /share/nextcloud
    chmod 777 /share/nextcloud
fi

# Is the directory valid
if [[ "$datadirectory" == *"/mnt/"* ]] && [ ! -f "$datadirectory"/index.html ]; then
    bashio::log.fatal "Data directory does not seem to be valid. Is your drive connected? Stopping to avoid corrupting the data directory."
    bashio::addon.stop
fi

# Remove nginx conf if existing
if [ -f /data/config/nginx/site-confs/default.conf ]; then
  rm /data/config/nginx/site-confs/default.conf
  # Avoid cannot enable app
  sed -i "s|front_controller_active true|front_controller_active false|g" /defaults/nginx/site-confs/default.conf.sample
fi

# Set permissions
mkdir -p "$datadirectory"
if bashio::config.true "skip_permissions_check"; then
  bashio::log.yellow "--------------------------------------------"
  bashio::log.yellow "Permissions check skipped : \"skip_permissions_check\" is true"
  bashio::log.yellow "--------------------------------------------"
elif [[ "$PUID" = "0" ]] && [[ "$PGID" = "0" ]]; then
  bashio::log.yellow "--------------------------------------------"
  bashio::log.yellow "Permissions check skipped : \"PUID and PGID are 0\" is true"
  bashio::log.yellow "--------------------------------------------"
else
  bashio::log.yellow "... setting permissions, this might take a long time. If it takes too long at each boot, you could instead activate skip_permissions_check in the addon options"
  chmod 755 -R "$datadirectory" || true
  chown -R "$PUID:$PGID" "$datadirectory" || true
fi

mkdir -p /scripts

echo "... done"
echo " "
