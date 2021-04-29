#!/usr/bin/with-contenv bashio

##########
# INIT   #
##########

# Define preferences line
cd /config/qBittorrent/
LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
LINE=$((LINE + 1))

##################
# Default folder #
##################

if bashio::config.has_value 'SavePath'; then
  DOWNLOADS=$(bashio::config 'SavePath')
  sed -i '/SavePath/d' qBittorrent.conf
  sed -i "$LINE i\Downloads\\\SavePath=$DOWNLOADS" qBittorrent.conf
  mkdir -p $DOWNLOADS || true
  chown -R abc:abc $DOWNLOADS || bashio::log.info "Error, please check default save folder configuration in addon"
  bashio::log.info "Downloads can be found in $DOWNLOADS"

else
  mkdir -p /share/qBittorrent || true
  chown -R abc:abc /share/qBittorrent

fi

################
# Correct Port #
################

sed -i '/PortRangeMin/d' qBittorrent.conf
sed -i "$LINE i\Connection\\\PortRangeMin=6881" qBittorrent.conf

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
# WHITELIST    #
################

cd /config/qBittorrent/
if bashio::config.has_value 'whitelist'; then
  WHITELIST=$(bashio::config 'whitelist')
  #clean data
  sed -i '/AuthSubnetWhitelist/d' qBittorrent.conf
  sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=true" qBittorrent.conf
  sed -i "$LINE i\WebUI\\\AuthSubnetWhitelist=$WHITELIST" qBittorrent.conf
  bashio::log.info "Whitelisted subsets will not require a password : $WHITELIST"
fi

###############
# USERNAME    #
###############

cd /config/qBittorrent/
if bashio::config.has_value 'Username'; then
  USERNAME=$(bashio::config 'Username')
  #clean data
  sed -i '/WebUI\\\Username/d' qBittorrent.conf
  #add data
  sed -i "$LINE i\WebUI\\\Username=$USERNAME" qBittorrent.conf
  bashio::log.info "WEBUI username set to $USERNAME"
fi

################
# Alternate UI #
################

# Clean data
sed -i '/AlternativeUIEnabled/d' qBittorrent.conf
sed -i '/RootFolder/d' qBittorrent.conf
rm -f -r /webui
mkdir -p /webui
chown abc:abc /webui

if bashio::config.has_value 'customUI'; then
  ### Variables
  CUSTOMUI=$(bashio::config 'customUI')
  bashio::log.info "Alternate UI enabled : $CUSTOMUI. If webui don't work, disable this option"

  ### Download WebUI
  case $CUSTOMUI in
  "vuetorrent") 
    curl -s -S -J -L -o /webui/release.zip $(curl -s https://api.github.com/repos/WDaan/VueTorrent/releases/latest | grep -o "http.*vuetorrent.zip") >/dev/null
    ;;

  "qbit-matUI")
    curl -s -S -J -L -o /webui/release.zip $(curl -s https://api.github.com/repos/bill-ahmed/qbit-matUI/releases/latest | grep -o "http.*Unix.*.zip") >/dev/null
    ;;

  "qb-web")
    curl -s -S -J -L -o /webui/release.zip $(curl -s https://api.github.com/repos/CzBiX/qb-web/releases | grep -o "http.*qb-web-.*zip") >/dev/null
    ;;
  esac

  ### Install WebUI
  mkdir -p /webui/$CUSTOMUI
  unzip -q /webui/release.zip -d /webui/$CUSTOMUI
  rm /webui/*.zip
  CUSTOMUIDIR="$(dirname "$(find /webui/$CUSTOMUI -iname "public" -type d)")"
  sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" /config/qBittorrent/qBittorrent.conf
  sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUIDIR" /config/qBittorrent/qBittorrent.conf
fi

##########
# CLOSE  #
##########

bashio::log.info "Default username/password : admin/adminadmin"
bashio::log.info "Configuration can be found in /config/qBittorrent"
