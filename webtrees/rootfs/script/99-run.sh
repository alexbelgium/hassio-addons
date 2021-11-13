#!/usr/bin/env bashio

####################
# GLOBAL VARIABLES #
####################

export BASE_URL=$(bashio::config 'BASE_URL'):$(bashio::addon.port 80)
#export LANG=$(bashio::config 'LANG')
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
    export BASE_URL="${BASE_URL/http:/https:}"

    #Communication
    bashio::log.info "Ssl enabled. If webui don't work, disable ssl or check your certificate paths"
fi

##############
# LAUNCH APP #
##############

bashio::log.info "Launching app, please wait"

# Change data location
echo "... update data with image"
OLD_WEBTREES_HOME=$WEBTREES_HOME
export WEBTREES_HOME="/share/webtrees"
cp -rn /var/www/webtrees "$(dirname "$OLD_WEBTREES_HOME")" &>/dev/null || true
mkdir -p $WEBTREES_HOME

echo "... update permissions"
chown -R www-data:www-data $OLD_WEBTREES_HOME
chown -R www-data:www-data $WEBTREES_HOME

# Make links with share
echo "... make links with data in /share"
for VOL in "data" "media" "modules_v4"; do
    mkdir -p $OLD_WEBTREES_HOME/$VOL
    cp -rn $OLD_WEBTREES_HOME/$VOL $WEBTREES_HOME || true
    rm -r $OLD_WEBTREES_HOME/$VOL || true
    ln -s $WEBTREES_HOME/$VOL $OLD_WEBTREES_HOME || true
done
chown -R www-data:www-data $WEBTREES_HOME

# Correct base url if needed
echo "... align base url with latest addon value"
if [ -f $WEBTREES_HOME/data/config.ini.php ]; then
    echo "Aligning base_url addon config"
    LINE=$(sed -n '/base_url/=' $WEBTREES_HOME/data/config.ini.php)
    sed -i "$LINE a base_url=\"$BASE_URL\"" $WEBTREES_HOME/data/config.ini.php
    sed -i "$LINE d" $WEBTREES_HOME/data/config.ini.php
fi || true

# Execute main script
echo "/docker-entrypoint.sh"
cd /
./docker-entrypoint.sh

############
# END INFO #
############

DB_NAME=$(echo $DB_NAME | tr -d '"')

bashio::log.info "Data is stored in $WEBTREES_HOME"
bashio::log.info "Webui can be accessed at : $BASE_URL"

exec apache2-foreground
