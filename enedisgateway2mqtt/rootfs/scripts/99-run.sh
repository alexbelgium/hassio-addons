#!/usr/bin/env bashio

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
DATABASESOURCE=$(dirname "${CONFIGSOURCE}")/database.sqlite

# Remoce config in data if existing 
[ -f /data/config.yaml ] && rm /data/config.yaml

# Check if config file is there, or create one from template
if [ -f $CONFIGSOURCE ]; then
    ln -s $CONFIGSOURCE /data
    bashio::log.info "Using config file found in $CONFIGSOURCE"
    
    # Check if yaml is valid
    yamllint -d relaxed --no-warnings $CONFIGSOURCE &> ERROR || EXIT_CODE=$?
    if [ $EXIT_CODE = 0 ]; then
      echo "Config file is a valid yaml"
    else
      cat ERROR 
      bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
      bashio::exit.nok
    fi
else
    # Create symlink for addon to create config
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    touch ${CONFIGSOURCE}
    ln -s $CONFIGSOURCE /data
    rm $CONFIGSOURCE
    # Need to restart
    bashio::log.fatal "Config file not found. The addon will create a new one, then stop. Please customize the file in $CONFIGSOURCE before restarting."
fi

# Check if database is here or create symlink
if [ -f $DATABASESOURCE ]; then
    ln -s $CONFIGSOURCE /data
    bashio::log.info "Using database file found in $DATABASESOURCE"
else
    # Create symlink for addon to create database
    mkdir -p "$(dirname "${DATABASESOURCE}")"
    touch ${DATABASESOURCE}
    ln -s $DATABASESOURCE /data
    rm $DATABASESOURCE
fi

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

export TZ=$(bashio::config "TZ")

# Test mode
if [ $TZ = "test" ]; then
  echo "secret mode found, launching script in /config/test.sh"
  cd /config
  chmod 777 test.sh
  ./test.sh 
fi

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
