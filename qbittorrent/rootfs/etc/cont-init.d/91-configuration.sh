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

### ADD WGET
apt-get update
apt-get install wget
rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

### IF VUETORRENT
if [ CUSTOMUI="vuetorrent" ];then
CUSTOMUI="WDaan/VueTorrent"
wget $(curl -s https://api.github.com/repos/$CUSTOMUI/releases/latest | grep 'browser_' | cut -d\" -f4)
mkdir -p /data/$CUSTOMUI
unzip release.zip -o -d /data/$CUSTOMUI/
rm release.zip
CUSTOMUIDIR=$(find /data/$CUSTOMUI -iname "public" -type d)
FOLDER="$(dirname "$CUSTOMUIDIR")"
sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" /config/qBittorrent/qBittorrent.conf
sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUIDIR" /config/qBittorrent/qBittorrent.conf
elif

### IF qbit-matUI
if [ CUSTOMUI="qbit" ];then
CUSTOMUI="bill-ahmed/qbit-matUI"
wget $(curl -s https://api.github.com/repos/$CUSTOMUI/releases/latest | grep 'browser_' | cut -d\" -f4)
mkdir -p /data/$CUSTOMUI
unzip release.zip -o -d /data/$CUSTOMUI/
rm release.zip
CUSTOMUIDIR=$(find /data/$CUSTOMUI -iname "public" -type d)
FOLDER="$(dirname "$CUSTOMUIDIR")"
sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" /config/qBittorrent/qBittorrent.conf
sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUIDIR" /config/qBittorrent/qBittorrent.conf
elif

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
