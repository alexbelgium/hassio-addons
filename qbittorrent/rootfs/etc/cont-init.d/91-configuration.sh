#!/usr/bin/with-contenv bashio

cd /config/qBittorrent/

# Clean HTTPS data
sed -i '/HTTPS/d' qBittorrent.conf

# Define preferences line
LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
LINE=$[LINE + 1] 

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables 
  CERTFILE=$(bashio::config 'certfile') 
  KEYFILE=$(bashio::config 'keyfile')
  sed -i "$LINE i\WebUI\\\HTTPS\\\Enabled=True" qBittorrent.conf
  sed -i "$LINE i\WebUI\\\HTTPS\\\CertificatePath=/ssl/$CERTFILE" qBittorrent.conf
  sed -i "$LINE i\WebUI\\\HTTPS\\\KeyPath=/ssl/$KEYFILE" qBittorrent.conf
fi

bashio::log.info "Default username/password : admin/adminadmin"

if bashio::config.has_value 'whitelist'; then
WHITELIST=$(bashio::config 'whitelist')
#clean data
sed -i '/AuthSubnetWhitelist/d' qBittorrent.conf
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=true" qBittorrent.conf
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelist=$WHITELIST" qBittorrent.conf
bashio::log.info "Whitelisted subsets will not require a password : $WHITELIST"
fi

bashio::log.info "Configuration can be found in /config/qBittorrent"
