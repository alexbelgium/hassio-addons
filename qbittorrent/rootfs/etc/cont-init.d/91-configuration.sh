#!/usr/bin/with-contenv bashio

# Define preferences line 
cd /config/qBittorrent/
LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
LINE=$[LINE + 1] 

################
# SSL CONFIG   #
################

# Clean data
sed -i '/HTTPS/d' qBittorrent.conf

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

################
# Alternate UI #
################

#clean data
sed -i '/AlternativeUIEnabled/d' qBittorrent.conf

if bashio::config.has_value 'customUI'; then
bashio::log.info "Alternate UI enabled. If webui don't work, disable this option"
CUSTOMUI=$(bashio::config 'customUI')
CUSTOMUI="/data/$CUSTOMUI"
sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" qBittorrent.conf
sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUI" qBittorrent.conf
fi

################
# WHITELIST    #
################

if bashio::config.has_value 'whitelist'; then
WHITELIST=$(bashio::config 'whitelist')
#clean data
sed -i '/AuthSubnetWhitelist/d' qBittorrent.conf
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=true" qBittorrent.conf
sed -i "$LINE i\WebUI\\\AuthSubnetWhitelist=$WHITELIST" qBittorrent.conf
bashio::log.info "Whitelisted subsets will not require a password : $WHITELIST"
fi

bashio::log.info "Default username/password : admin/adminadmin"
bashio::log.info "Configuration can be found in /config/qBittorrent"
