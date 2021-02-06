#!/usr/bin/with-contenv bashio

# Clean HTTPS data
sed -i '/HTTPS/d' /config/qBittorrent/qBittorrent.conf

# Define preferences line
LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
LINE=$[LINE + 1] 

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables 
  CERTFILE=$(bashio::config 'certfile') 
  KEYFILE=$(bashio::config 'keyfile') 
  #Check if certificates exist 
  #if [ bashio::fs.file_exists "/ssl/$CERTFILE" ] && [ bashio::fs.file_exists "/ssl/$KEYFILE" ]; then
  cd /config/qBittorrent
  sed -i "$LINE i\WebUI\\\HTTPS\\\Enabled=True" qBittorrent.conf
  sed -i "$LINE i\WebUI\\\HTTPS\\\CertificatePath=/ssl/$CERTFILE" qBittorrent.conf
  sed -i "$LINE i\WebUI\\\HTTPS\\\KeyPath=/ssl/$KEYFILE" qBittorrent.conf
  #else bashio::log.error "Certificates not found in $CERTFILE and/or $KEYFILE" 
  #fi 
fi

bashio::log.info "Default username/password : admin/adminadmin"

if bashio::config.has_value 'whitelist'; then
WHITELIST=$(bashio::config 'whitelist')
#clean data
sed -i '/AuthSubnetWhitelist/d' /config/qBittorrent/qBittorrent.conf
cd /config/qBittorrent
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=true" qBittorrent.conf
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelist=$WHITELIST" qBittorrent.conf
bashio::log.info "Whitelisted subsets will not require a password : $WHITELIST"
fi

bashio::log.info "Configuration can be found in /config/qBittorrent"
