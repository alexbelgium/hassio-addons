#!/usr/bin/env bashio

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Check if config file is there, or create one from template
if [ -f $CONFIGSOURCE ]; then
    echo "Using config file found in $CONFIGSOURCE"
else
    echo "No config file, creating one from template"
    # Create folder
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    # Downloading template
    TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/gazpar2mqtt/rootfs/templates/config.yaml"
    curl -L -f -s $TEMPLATESOURCE --output $CONFIGSOURCE
    # Placing template in config
    #cp config.yaml "$(dirname "${CONFIGSOURCE}")"
    # Need to restart
    bashio::log.fatal "Config file not found, creating a new one. Please customize the file in $CONFIGSOURCE before restarting."
    bashio::exit.nok
fi

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed --no-warnings $CONFIGSOURCE &>ERROR || EXIT_CODE=$?
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

# Export all yaml entries as env variables
# Helper function
function parse_yaml {
    local prefix=$2 || local prefix=""
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
    -e "s| #.*$||g" \
    -e "s|#.*$||g" \
    -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
     }'
}

# Get variables and export
bashio::log.info "Starting the app with the variables in /config/gazpar2mqtt"
# Get list of parameters in a file
parse_yaml "$CONFIGSOURCE" "" >/tmpfile
while IFS= read -r line
do
    # Clean output
    line=${line//[\"\']/}
    # Check if secret
    if [[ "${line}" == *'!secret '* ]]; then
        echo "secret detected"
        secret=${line#*secret }
        # Check if single match
        secretnum=$(sed -n "/$secret:/=" /config/secrets.yaml)
        [[ $(echo $secretnum) == *' '* ]] && bashio::log.fatal "There are multiple matches for your password name. Please check your secrets.yaml file" && bashio::exit.nok
        # Get text
        secret=$(sed -n "/$secret:/p" /config/secrets.yaml)
        secret=${secret#*: }
        line="${line%%=*}=$secret"
    fi
    # Data validation
    if [[ $line =~ ^.+[=].+$ ]]; then
        export $line # Export the variable
        bashio::log.blue "$line"
    else
        bashio::log.fatal "$line does not follow the structure KEY=text"
        bashio::exit.nok
    fi
done < "/tmpfile"

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/gazpar2mqtt.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
