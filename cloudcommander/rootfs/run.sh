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
# MOUNT LOCAL SCRIPT #
######################
chown $(id -u):$(id -g) /92-local_mounts.sh
chmod a+x /92-local_mounts.sh
sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' /92-local_mounts.sh
/./92-local_mounts.sh &
true # Prevents script crash on failure

######################
# EXECUTE SMB SCRIPT #
######################
chown $(id -u):$(id -g) /92-smb_mounts.sh
chmod a+x /92-smb_mounts.sh
sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' /92-smb_mounts.sh
/./92-smb_mounts.sh &
true # Prevents script crash on failure

#################
# NGINX SETTING #
#################

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

CLOUDCMD_PREFIX=$(bashio::addon.ingress_entry)
export CLOUDCMD_PREFIX

declare ADDON_PROTOCOL=http
if bashio::config.true 'ssl'; then
  ADDON_PROTOCOL=https
fi

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${CLOUDCMD_PREFIX}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
  CUSTOMOPTIONS=" $(bashio::config 'CUSTOM_OPTIONS')"
else
  CUSTOMOPTIONS=""
fi

if bashio::config.has_value 'DROPBOX_TOKEN'; then
  DROPBOX_TOKEN="--dropbox --dropbox-token $(bashio::config 'DROPBOX_TOKEN')"
else
  DROPBOX_TOKEN=""
fi

bashio::log.info "Starting..."

./usr/src/app/bin/cloudcmd.mjs '"'$DROPBOX_TOKEN$CUSTOMOPTIONS'"' &
bashio::net.wait_for 8000 localhost 900 || true
bashio::log.info "Started !"
exec nginx
