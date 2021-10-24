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
[ $DB_TYPE = "sqlite" ] && bashio::log.info "Using a local sqlite database $WEBTREES_HOME/$DB_NAME please wait then login. Default credentials : $WT_USER : $WT_PASS"

#####################
# DATABASE LOCATION #
#####################

# Change data location
NEW_WEBTREES_HOME=$(bashio::config 'WEBTREES_HOME')

if [ ! -d $NEW_WEBTREES_HOME ]; then
  export WEBTREES_HOME="/data/webtrees"
  grep -rl "/var/www/webtrees" /etc/ | xargs sed -i 's|/var/www/webtrees|$WEBTREES_HOME|g' \ 
else
  bashio::log.fatal "$WEBTREES_HOME not found, using internal addon data"
fi

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
  bashio::log.info "Ssl enabled. If webui don't work, disable ssl or check your certificate paths"
fi

##############
# LAUNCH APP #
##############

bashio::log.info "Launching app, please wait"
# Remove previous config to allow addon options to refresh
rm /data/webtrees/data/config.ini.php 2>/dev/null || true

# Change data location
cp -rn /var/www/webtrees /data
chown -R www-data:www-data /data/webtrees

# Execute main script
cd /
./docker-entrypoint.sh >/dev/null

############
# END INFO #
############

DB_NAME=$(echo $DB_NAME | tr -d '"')

bashio::log.info "Webui can be accessed at : $BASE_URL"

exec apache2-foreground
