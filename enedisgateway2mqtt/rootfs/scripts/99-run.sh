#!/usr/bin/env bashio

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
DATABASESOURCE="$(dirname "${CONFIGSOURCE}")/enedisgateway.db"

# Make sure folder exist
mkdir -p "$(dirname "${CONFIGSOURCE}")"
mkdir -p "$(dirname "${DATABASESOURCE}")"

# Check absence of config file
if [ -f /data/config.yaml ] && [ ! -L /data/config.yaml ]; then
    bashio::log.warning "A current config was found in /data, it is backuped to ${CONFIGSOURCE}.bak"
    mv /data/config.yaml $CONFIGSOURCE.bak
fi

# Check if config file is there, or create one from template
if [ -f $CONFIGSOURCE ]; then
    # Create symlink if not existing yet
    [ ! -L /data/config.yaml ] && ln -sf $CONFIGSOURCE /data
    bashio::log.info "Using config file found in $CONFIGSOURCE"
    
    # Check if yaml is valid
    EXIT_CODE=0 
    yamllint -d relaxed --no-warnings $CONFIGSOURCE &> ERROR || EXIT_CODE=$?
    if [ $EXIT_CODE = 0 ]; then
    echo "Config file is a valid yaml"
    else
      cat ERROR 
      bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above. You can check yaml validity with the online tool yamllint.com"
      bashio::exit.nok
    fi
else
    # Create symlink for addon to create config
    touch ${CONFIGSOURCE}
    ln -sf $CONFIGSOURCE /data
    rm $CONFIGSOURCE
    # Need to restart
    bashio::log.fatal "Config file not found. The addon will create a new one, then stop. Please customize the file in $CONFIGSOURCE before restarting."
fi

# Check absence of database file
if [ -f /data/enedisgateway.db ] && [ ! -L /data/enedisgateway.db ]; then
    bashio::log.warning "A current database was found in /data, it is backuped to ${DATABASESOURCE}.bak"
    mv /data/enedisgateway.db $DATABASESOURCE.bak
fi

# Check if database is here or create symlink
if [ -f $DATABASESOURCE ]; then
    # Create symlink if not existing yet
    [ ! -L /data/enedisgateway.db ] && ln -sf ${DATABASESOURCE} /data
    bashio::log.info "Using database file found in $DATABASESOURCE"
else
   # Create symlink for addon to create database
   touch ${DATABASESOURCE}
   ln -sf $DATABASESOURCE /data
   rm $DATABASESOURCE
fi

################
# Set timezone #
################
if bashio::config.has_value "TZ"; then
    TZ=$(bashio::config "TZ")
    if [ -f /usr/share/zoneinfo/$TZ ]; then
        bashio::log.info "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    else
    bashio::log.warning "Timezone $TZ is invalid, it will be kept to default value of $(cat /etc/timezone)"
fi

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

# Test mode
if [ $TZ = "test" ]; then
  echo "secret mode found, launching script in /config/test.sh"
  cd /config
  chmod 777 test.sh
  ./test.sh 
fi

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
