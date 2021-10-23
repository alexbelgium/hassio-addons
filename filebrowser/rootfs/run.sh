#!/usr/bin/env bashio

##########
# BANNER #
##########

if bashio::supervisor.ping; then
  bashio::log.blue \
  '-----------------------------------------------------------'
  bashio::log.blue " Add-on: $(bashio::addon.name)"
  bashio::log.blue " $(bashio::addon.description)"
  bashio::log.blue \
  '-----------------------------------------------------------'

  bashio::log.blue " Add-on version: $(bashio::addon.version)"
  if bashio::var.true "$(bashio::addon.update_available)"; then
    bashio::log.magenta ' There is an update available for this add-on!'
    bashio::log.magenta \
    " Latest add-on version: $(bashio::addon.version_latest)"
    bashio::log.magenta ' Please consider upgrading as soon as possible.'
  else
    bashio::log.green ' You are running the latest version of this add-on.'
  fi

  bashio::log.blue " System: $(bashio::info.operating_system)" \
  " ($(bashio::info.arch) / $(bashio::info.machine))"
  bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
  bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

  bashio::log.blue \
  '-----------------------------------------------------------'
  bashio::log.blue \
  ' Please, share the above information when looking for help'
  bashio::log.blue \
  ' or support in, e.g., GitHub, forums or the Discord chat.'
  bashio::log.green \
  ' https://github.com/alexbelgium/hassio-addons'
  bashio::log.blue \
  '-----------------------------------------------------------'
fi

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
  bashio::log.info 'Mounting local hdd...'
  #bashio::require.unprotected
  MOREDISKS=$(bashio::config 'localdisks')
  bashio::log.info "Local Disks mounting.. ${MOREDISKS}" && \
  for disk in ${MOREDISKS//,/ }; do # Separate comma separated values
    bashio::log.info "Mount ${disk}"
    mkdir -p /share/$disk && \
    if [ ! -d /share/$disk ]; then
      echo "Creating /share/$disk"
      mkdir -p /share/$disk
      chown -R abc:abc /share/$disk
    fi
    mount /dev/$disk /share/$disk && \
    bashio::log.info "Success!"
  done || \
  bashio::log.warning "Protection mode is ON. Unable to mount local drives!"
fi || true

######################
# EXECUTE SMB SCRIPT #
######################
chown $(id -u):$(id -g) /92-smb_mounts.sh
chmod a+x /92-smb_mounts.sh
/./92-smb_mounts.sh

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

bashio::log.info "Starting..."

/./filebrowser $CERTFILE $KEYFILE --root=/ --address=0.0.0.0 --database=/config/filebrowser/filebrowser.dB $NOAUTH &
bashio::net.wait_for 8080 localhost 900 || true
bashio::log.info "Started !"
exec nginx
