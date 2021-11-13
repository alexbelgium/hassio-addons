#!/usr/bin/env bashio

###################
# SSL CONFIG v1.0 #
###################

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables
  CERTFILE="-t /ssl/$(bashio::config 'certfile')"
  KEYFILE="-k /ssl/$(bashio::config 'keyfile')"
else
  CERTFILE=""
  KEYFILE=""
fi

####################
# SET UID GID v1.0 #
####################
bashio::log.info 'PUID GUID set to root'
PUID=0
PGID=0

#################
# NGINX SETTING #
#################

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

FB_BASEURL=$(bashio::addon.ingress_entry)
export FB_BASEURL

declare ADDON_PROTOCOL=http
# Generate Ingress configuration
if bashio::config.true 'ssl'; then
  ADDON_PROTOCOL=https
fi

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${FB_BASEURL}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

######################
# LAUNCH FILEBROWSER #
######################

NOAUTH=""

if bashio::config.true 'NoAuth'; then
  if ! bashio::fs.file_exists "/data/noauth"; then
    rm /data/auth &>/dev/null || true
    rm /config/filebrowser/filebrowser.dB &>/dev/null || true
    touch /data/noauth
    NOAUTH="--noauth"
    bashio::log.warning "Auth method change, database reset"
  fi
  bashio::log.info "NoAuth option selected"
else
  if ! bashio::fs.file_exists "/data/auth"; then
    rm /data/noauth &>/dev/null || true
    rm /config/filebrowser/filebrowser.dB &>/dev/null || true
    touch /data/auth
    bashio::log.warning "Auth method change, database reset"
  fi
  bashio::log.info "Default username/password : admin/admin"
fi

if bashio::config.has_value 'base_folder'; then
  BASE_FOLDER=$(bashio::config 'base_folder')
else
  BASE_FOLDER=/
fi

bashio::log.info "Starting..."

/./filebrowser $CERTFILE $KEYFILE --root=$BASE_FOLDER --address=0.0.0.0 --database=/config/filebrowser/filebrowser.dB $NOAUTH &
bashio::net.wait_for 8080 localhost 900 || true
bashio::log.info "Started !"
exec nginx
