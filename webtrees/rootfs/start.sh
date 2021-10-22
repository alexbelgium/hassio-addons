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

####################
# GLOBAL VARIABLES #
####################

export BASE_URL=$(bashio::config 'BASE_URL'):$(bashio::addon.port 80)
export LANG=$(bashio::config 'LANG')
export DB_TYPE=$(bashio::config 'DB_TYPE')
export WT_USER=$(bashio::config 'WT_USER')
export WT_NAME=$(bashio::config 'WT_NAME')
export WT_PASS=$(bashio::config 'WT_PASS')
export WT_EMAIL=$(bashio::config 'WT_EMAIL')

################
# SSL CONFIG   #
################

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  
  #set variables
  CERTFILE=$(bashio::config 'certfile')
  KEYFILE=$(bashio::config 'keyfile')
  
  #Replace variables
  sed -i "s|/certs/webtrees.crt|/ssl/$CERTFILE|g" /etc/apache2/sites-available/default-ssl.conf
  sed -i "s|/certs/webtrees.key|/ssl/$KEYFILE|g" /etc/apache2/sites-available/default-ssl.conf
  sed -i "s|/certs/webtrees.crt|/ssl/$CERTFILE|g" /etc/apache2/sites-available/webtrees-ssl.conf
  sed -i "s|/certs/webtrees.key|/ssl/$KEYFILE|g" /etc/apache2/sites-available/webtrees-ssl.conf
  
  #Send env variables
  export HTTPS=true
  export SSL=true
  BASE_URL=$BASE_URL:$(bashio::addon.port 443)
  export BASE_URL="${BASE_URL/http/https}"
  
  #Communication
  bashio::log.info "Ssl enabled at path $BASE_URL. If webui don't work, disable ssl or check your certificate paths"

fi

##############
# LAUNCH APP #
##############

cd/
./docker-entrypoint.sh
