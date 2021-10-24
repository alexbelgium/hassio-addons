#!/usr/bin/env bashio

###########
# SCRIPTS #
###########

for SCRIPTS in "/00-banner.sh"; do
  echo $SCRIPTS
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS
  /.$SCRIPTS &&
  true # Prevents script crash on failure
done

####################
# GLOBAL VARIABLES #
####################

export BASE_URL=$(bashio::config 'BASE_URL'):$(bashio::addon.port 80)
export LANG=$(bashio::config 'LANG')
export DB_TYPE=$(bashio::config 'DB_TYPE')
[ $DB_TYPE = "sqlite" ] && bashio::log.info "Using a local sqlite database $WEBTREES_HOME/$DB_NAME please wait then login. Default credentials : $WT_USER : $WT_PASS"

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

if bashio::config.true 'database_in_share'; then
  export WEBTREES_HOME="/share/webtrees"
  grep -rl "/data/webtrees" /etc/ | xargs sed -i 's|/data/webtrees|$WEBTREES_HOME|g' || true
  grep -rl "/var/www/webtrees" /etc/ | xargs sed -i 's|/var/www/webtrees|$WEBTREES_HOME|g' || true
fi

bashio::log.info "Data stored in $WEBTREES_HOME"

# Change data location
cp -rn /var/www/webtrees "$(dirname "$WEBTREES_HOME")"
chown -R www-data:www-data $WEBTREES_HOME

# Execute main script
cd /
./docker-entrypoint.sh >/dev/null

############
# END INFO #
############

DB_NAME=$(echo $DB_NAME | tr -d '"')

bashio::log.info "Webui can be accessed at : $BASE_URL"

exec apache2-foreground
