#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

##########
# INIT   #
##########

# Define preferences line
CONFIG_LOCATION=/config/addons_config/qBittorrent
mkdir -p "$CONFIG_LOCATION"

# copy default config
if [ ! -f "$CONFIG_LOCATION"/qBittorrent.conf ]; then
    cp /defaults/qBittorrent.conf "$CONFIG_LOCATION"/qBittorrent.conf
fi

cd "$CONFIG_LOCATION"/ || true
LINE=$(sed -n '/\[Preferences\]/=' qBittorrent.conf) || bashio::exit.nok "qBittorrent.conf not valid"
LINE=$((LINE + 1))

# Remove unused folders
if [ -d "$CONFIG_LOCATION"/addons_config ]; then rm -r "$CONFIG_LOCATION"/addons_config; fi
if [ -d "$CONFIG_LOCATION"/qBittorrent ]; then rm -r "$CONFIG_LOCATION"/qBittorrent; fi

###########
# TIMEOUT #
###########

if bashio::config.has_value 'run_duration'; then
    echo "Timer mode set"
else
    rm -r /etc/services.d/timer
fi

##################
# Default folder #
##################

# Set configuration
if bashio::config.has_value 'SavePath'; then

    # Set variable
    DOWNLOADS=$(bashio::config 'SavePath')
    DOWNLOADS=${DOWNLOADS:-/share/downloads} # Default if not set

    # Replace save path
    sed -i -e "/SavePath/d" \
        -e "/\[Preferences\]/a Downloads\\\SavePath=$DOWNLOADS" \
        -e "/\[AutoRun\]/a Downloads\\\DefaultSavePath=$DOWNLOADS" \
        -e "/\[Preferences\]/a Downloads\\\DefaultSavePath=$DOWNLOADS" \
        -e "/\[BitTorrent\]/a Downloads\\\DefaultSavePath=$DOWNLOADS" \
        -e "/\[BitTorrent\]/a Session\\\DefaultSavePath=$DOWNLOADS" qBittorrent.conf


    # Info
    bashio::log.info "Downloads can be found in $DOWNLOADS"
fi

# Create default location
mkdir -p "$DOWNLOADS" || bashio::log.fatal "Error : folder defined in SavePath doesn't exist and can't be created. Check path"
chown -R "$PUID:$PGID" "$DOWNLOADS" || bashio::log.fatal "Error, please check default save folder configuration in addon"

##############
# Avoid bugs #
##############

sed -i -e '/CSRFProtection/d' \
    -e '/ClickjackingProtection/d' \
    -e '/HostHeaderValidation/d' \
    -e '/WebUI\Address/d' \
    -e "$LINE i\WebUI\\\CSRFProtection=false" \
    -e "$LINE i\WebUI\\\ClickjackingProtection=false" \
    -e "$LINE i\WebUI\\\HostHeaderValidation=false" \
    -e "$LINE i\WebUI\\\Address=*" qBittorrent.conf
#sed -i '/WebUI\ReverseProxySupportEnabled/d' qBittorrent.conf
#sed -i "$LINE i\WebUI\\\ReverseProxySupportEnabled=true" qBittorrent.conf

################
# Correct Port #
################

# sed -i '/PortRangeMin/d' qBittorrent.conf
# sed -i "$LINE i\Connection\\\PortRangeMin=6881" qBittorrent.conf
sed -i "s|6881|59595|g" qBittorrent.conf # Correction if required

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

cd "$CONFIG_LOCATION"/ || true

WHITELIST="$(bashio::config 'whitelist')"
#clean data
sed -i '/AuthSubnetWhitelist/d' qBittorrent.conf

if [[ "${#WHITELIST}" -gt 5 ]]; then
    sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=true" qBittorrent.conf
    sed -i "$LINE i\WebUI\\\AuthSubnetWhitelist=$WHITELIST" qBittorrent.conf
    bashio::log.info "Whitelisted subsets will not require a password : $WHITELIST"
else
    sed -i "$LINE i\WebUI\\\AuthSubnetWhitelistEnabled=false" qBittorrent.conf
    bashio::log.info "Whitelisted subsets deactivated"
fi

###############
# USERNAME    #
###############

cd "$CONFIG_LOCATION"/ || true
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

CUSTOMUI=$(bashio::config 'customUI')

# Clean data if not custom
if [ ! "$CUSTOMUI" = custom ]; then
    sed -i '/AlternativeUIEnabled/d' qBittorrent.conf
    sed -i '/RootFolder/d' qBittorrent.conf
    rm -f -r /webui
    mkdir -p /webui
    chown "$PUID:$PGID" /webui
fi

# Update ingress webui
curl -f -s -S -O -J -L "$(curl -f -s https://api.github.com/repos/WDaan/VueTorrent/releases | grep -o "http.*vuetorrent.zip" | head -1)" >/dev/null
unzip -o vuetorrent.zip -d / >/dev/null
rm vuetorrent.zip

# Install webui
if bashio::config.has_value 'customUI' && [ ! "$CUSTOMUI" = default ] && [ ! "$CUSTOMUI" = custom ]; then
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
    sed -i "$LINE i\WebUI\\\AlternativeUIEnabled=true" "$CONFIG_LOCATION"/qBittorrent.conf
    sed -i "$LINE i\WebUI\\\RootFolder=$CUSTOMUIDIR" "$CONFIG_LOCATION"/qBittorrent.conf
    # Set nginx
    #sed -i "s=/vuetorrent/public/=$CUSTOMUIDIR/public/=g" /etc/nginx/servers/ingress.conf
    #sed -i "s=vue.torrent=$CUSTOMUI.torrent=g" /etc/nginx/servers/ingress.conf

fi

##########
# CLOSE  #
##########

bashio::log.info "Default username/password : admin/adminadmin"
bashio::log.info "Configuration can be found in $CONFIG_LOCATION"
