#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')
if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then LOCATION=/config/addons_config/${HOSTNAME#*-}; fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"
# shellcheck disable=SC2013,SC2086
for file in $(grep -sril "/config" /etc /defaults); do sed -i "s=/config=$LOCATION=g" $file; done
# Modify new location for database
sed -i "s|%%LOCATION%%|$LOCATION|g" /etc/cont-init.d/99-database_clean.sh

# Create folders
echo "Creating $LOCATION"
mkdir -p "$LOCATION" "$LOCATION"/data "$LOCATION"/cache "$LOCATION"/log "$LOCATION"/web

# Custom web location
cp -rn /usr/share/jellyfin/web/* "$LOCATION"/web/
sed -i "s|/usr/share/jellyfin|$LOCATION|g" /etc/nginx/servers/ingress.conf

# Custom transcode location
mkdir -p /data/transcodes
if [ -d "$LOCATION"/data/transcodes ]; then
    cp -rT "$LOCATION"/data/transcodes /data/transcodes || true
    rm -r "$LOCATION"/data/transcodes
fi
ln -s /data/transcodes "$LOCATION"/data/transcodes
chown -R "$PUID":"$PGID" /data/transcodes

# Permissions
bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION"
