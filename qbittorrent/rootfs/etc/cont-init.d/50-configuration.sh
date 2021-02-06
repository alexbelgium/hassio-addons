#!/usr/bin/with-contenv bashio

#clean HTTPS data
sed -i '/HTTPS/d' /config/qBittorrent/qBittorrent.conf

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables 
  CERTFILE=$(bashio::config 'certfile') 
  KEYFILE=$(bashio::config 'keyfile') 
  #Check if certificates exist 
  if [ bashio::fs.file_exists "/ssl/$CERTFILE" ] && [ bashio::fs.file_exists "/ssl/$KEYFILE" ]; then 
    echo 'WebUI\HTTPS\Enabled=True' >> /config/qbittorrent.conf 
    echo "WebUI\HTTPS\CertificatePath=/ssl/$CERTFILE" >> /config/qbittorrent.conf 
    echo "WebUI\HTTPS\KeyPath=/ssl/$KEYFILE" >> /config/qbittorrent.conf 
  else bashio::log.error "Certificates not found in $CERTFILE and/or $KEYFILE" 
  fi 
fi

bashio::log.info "Default username/password : admin/adminadmin"
bashio::log.info "Configuration can be found in /config/qBittorrent"
