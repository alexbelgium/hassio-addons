#!/usr/bin/env bashio

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Check if config file is there, or create one from template
if [ -f $CONFIGSOURCE ]; then
    echo "Using config file found in $CONFIGSOURCE"
else
    echo "No config file, creating one from template"
    # Create folder
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    # Placing template in config
    cp /data/config.yaml "$(dirname "${CONFIGSOURCE}")" &>/dev/null \
    || cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"
    # Need to restart
    bashio::log.fatal "Config file not found, creating a new one. Please customize the file in $CONFIGSOURCE before restarting."
    bashio::exit.nok
fi

# Check if yaml is valid
#yamllint -d relaxed --no-warnings $CONFIGSOURCE &> ERROR || EXIT_CODE=$?
if [ $EXIT_CODE = 0 ]; then
    echo "Config file is a valid yaml"
else
    cat ERROR 
    bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
    bashio::exit.nok
fi

# Create symlink
[ -f /data/config.yaml ] && rm /data/config.yaml
ln -s $CONFIGSOURCE /data
echo "Symlink created"

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
