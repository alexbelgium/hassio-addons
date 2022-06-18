#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##########
# INIT   #
##########

# Define preferences line
mkdir -p /config/qBittorrent
cd /config/qBittorrent/ || true
LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
LINE=$((LINE + 1))

###########
# TIMEOUT #
###########

if bashio::config.has_value 'run_duration'; then
    rm /etc/services.d/qbittorrent/run
    mv /etc/services.d/qbittorrent/timer /etc/services.d/qbittorrent/run
    chmod +x /etc/services.d/qbittorrent/run
else
    rm /etc/services.d/qbittorrent/timer
fi

##################
# Default folder #
##################

# Set variable
DOWNLOADS=$(bashio::config 'SavePath')

# Set configuration
if bashio::config.has_value 'SavePath'; then

    # Replace save path
    CURRENTSAVEPATH=$(sed -n '/Downloads\\SavePath/p' qBittorrent.conf)
    sed -i "s|${CURRENTSAVEPATH#*=}|$DOWNLOADS|g" qBittorrent.conf 2>/dev/null || true

    # Replace session save path
    CURRENTSAVEPATH=$(sed -n '/Session\\DefaultSavePath/p' qBittorrent.conf)
    sed -i "s|${CURRENTSAVEPATH#*=}|$DOWNLOADS|g" qBittorrent.conf 2>/dev/null || true

    # Info
    bashio::log.info "Downloads can be found in $DOWNLOADS"
fi

# Create default location
mkdir -p "$DOWNLOADS" || bashio::log.fatal "Error : folder defined in SavePath doesn't exist and can't be created. Check path"
chown -R abc:abc "$DOWNLOADS" || bashio::log.fatal "Error, please check default save folder configuration in addon"

##############
# Avoid bugs #
##############

sed -i '/CSRFProtection/d' qBittorrent.conf
sed -i '/ClickjackingProtection/d' qBittorrent.conf
sed -i '/HostHeaderValidation/d' qBittorrent.conf
sed -i '/WebUI\Address/d' qBittorrent.conf
#sed -i '/WebUI\ReverseProxySupportEnabled/d' qBittorrent.conf
sed -i "$LINE i\WebUI\\\CSRFProtection=false" qBittorrent.conf
sed -i "$LINE i\WebUI\\\ClickjackingProtection=false" qBittorrent.conf
#sed -i "$LINE i\WebUI\\\ReverseProxySupportEnabled=true" qBittorrent.conf
sed -i "$LINE i\WebUI\\\HostHeaderValidation=false" qBittorrent.conf
sed -i "$LINE i\WebUI\\\Address=*" qBittorrent.conf

################
# Correct Port #
################

# sed -i '/PortRangeMin/d' qBittorrent.conf
# sed -i "$LINE i\Connection\\\PortRangeMin=6881" qBittorrent.conf

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

    #Modify configuration
    sed -i "$LINE i\WebUI\\\HTTPS\\\Enabled=True" qBittorrent.conf
    sed -i "$LINE i\WebUI\\\HTTPS\\\CertificatePath=/ssl/$CERTFILE" qBittorrent.conf
    sed -i "$LINE i\WebUI\\\HTTPS\\\KeyPath=/ssl/$KEYFILE" qBittorrent.conf
fi

################
# WHITELIST    #
################

cd /config/qBittorrent/ || true
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

cd /config/qBittorrent/ || true
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

CUSTOMUI=$(bashio::config 'customUI')
if bashio::config.has_value 'customUI' && [ ! "$CUSTOMUI" = default ]; then
    ### Variables
    bashio::log.info "Alternate UI enabled : $CUSTOMUI. If webui don't work, disable this option"

    ### Download WebUI
    case $CUSTOMUI in
        "vuetorrent")
            curl -f -s -S -J -L -o /webui/release.zip "$(curl -f -s https://api.github.com/repos/WDaan/VueTorrent/releases/latest | grep -o "http.*vuetorrent.zip" | head -1)" >/dev/null
            ;;

        "qbit-matUI")
            curl -f -s -S -J -L -o /webui/release.zip "$(curl -f -s https://api.github.com/repos/bill-ahmed/qbit-matUI/releases/latest | grep -o "http.*Unix.*.zip" | head -1)" >/dev/null
            ;;

        "qb-web")
            curl -f -s -S -J -L -o /webui/release.zip "$(curl -f -s https://api.github.com/repos/CzBiX/qb-web/releases | grep -o "http.*qb-web-.*zip" | head -1)" >/dev/null
            ;;

    esac

    ### Install WebUI
    mkdir -p /webui/"$CUSTOMUI"
    unzip -q /webui/release.zip -d /webui/"$CUSTOMUI"
    rm /webui/*.zip
    CUSTOMUIDIR="$(dirname "$(find /webui/"$CUSTOMUI" -iname "public" -type d)")"
    # Set qbittorrent
    sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" /config/qBittorrent/qBittorrent.conf
    sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUIDIR" /config/qBittorrent/qBittorrent.conf
    # Set nginx
    #sed -i "s=/vuetorrent/public/=$CUSTOMUIDIR/public/=g" /etc/nginx/servers/ingress.conf
    #sed -i "s=vue.torrent=$CUSTOMUI.torrent=g" /etc/nginx/servers/ingress.conf

fi

##########
# CLOSE  #
##########

bashio::log.info "Default username/password : admin/adminadmin"
bashio::log.info "Configuration can be found in /config/qBittorrent"
