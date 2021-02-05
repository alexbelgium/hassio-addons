#!/usr/bin/with-contenv bashio

if [ bashio::config.exists 'certfile' ] && [ bashio::config.exists 'keyfile' ]; then
#Set variables
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
bashio::log.info "Ssl certificates options were set..."
bashio::log.info "... cleaning previous information"
sed -i '/HTTPS/d' /config/qBittorrent/qBittorrent.conf 

#Check if certificates exist
  if [ bashio::fs.file_exists "$CERTFILE" ] && [ ! bashio::fs.file_exists "$KEYFILE" ]; then  
  echo 'WebUI\HTTPS\Enabled=True' >> /config/qbittorrent.conf
  echo "WebUI\HTTPS\CertificatePath=$CERTFILE" >> /config/qbittorrent.conf
  echo "WebUI\HTTPS\KeyPath=$KEYFILE" >> /config/qbittorrent.conf
  bashio::log.info "... and certificates were set"
  else
  bashio::log.info "... but certificates not found in $CERTFILE and/or $KEYFILE "
  fi
fi

bashio::log.info "Default username/password : admin/adminadmin"
