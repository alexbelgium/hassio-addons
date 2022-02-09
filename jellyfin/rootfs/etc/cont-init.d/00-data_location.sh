#!/usr/bin/with-contenv bashio
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")
LOCATION=$(bashio::config 'data_location')

bashio::log.info "Setting data location to $LOCATION" 
sed -i "s|/config|$LOCATION|g" /etc/services.d/jellyfin/run
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/10-adduser
sed -i "s|/config|$LOCATION|g" /etc/cont-init.d/30-config

echo "Creating $LOCATION"
mkdir -p "$LOCATION"

bashio::log.info "Setting ownership to $PUID:$GUID" 
chown "$PUID":"$GUID" "$LOCATION"
