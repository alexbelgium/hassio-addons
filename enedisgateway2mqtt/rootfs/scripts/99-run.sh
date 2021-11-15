#!/usr/bin/env bashio

############################
# Check if config is there #
############################

CONFIGSOURCE="/config/enedisgateway2mqtt/config.yaml"

# Check if config file is there, or create template
if [ -f $CONFIGSOURCE ]; then
    echo "Using config file found in $CONFIGSOURCE"
else
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"
    bashio::log.fatal "Config file not found, creating a new one. Please customize the file in $CONFIGSOURCE"
    sleep 10
    bashio::exit.nok
fi

# Check if yaml is valid
if [ yamllint $CONFIGSOURCE ]; then
    echo "Config file is a valid yaml"
else
    bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE"
    bashio::exit.nok
fi




#################
# Create config #
#################

# Create the config file
CONFIGSOURCE="/config/enedisgateway2mqtt/enedisgateway2mqtt.conf" #file
mkdir -p "$(dirname "${CONFIGSOURCE}")"                           #create dir
touch ${CONFIGSOURCE}                                             #create file

##########################
# Read all addon options #
##########################
bashio::log.info "All variables defined in the addon will be exported to the config file located in /config/enedisgateway2mqtt"

# Get the default keys from the original file
JSONSOURCE="/data/options.json"
mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})
# For all keys in options.json
for KEYS in ${arr[@]}; do
    # if the custom_var field is used
    if [ "${KEYS}" = "custom_var" ]; then
        VALUES=$(jq .$KEYS ${JSONSOURCE}) # Get list of custom elements
        VALUES=${VALUES:1:-1}             # Remove first and last ""
        for SUBKEYS in ${VALUES//,/ }; do
            [[ ! $SUBKEYS =~ ^.+[=].+$ ]] && bashio::log.warning "Your custom_var field $SUBKEYS does not follow the structure KEY=\"text\",KEY2=\"text2\" it will be ignored" && continue || true
            # Remove the key if already existing
            sed -i "/$(echo "${SUBKEYS%%=*}")/ d" ${CONFIGSOURCE}
            # Remove apostrophes
            SUBKEYS=${SUBKEYS//[\"\']/}
            # Write it in the config file
            echo ${SUBKEYS} >>${CONFIGSOURCE}
            # Say it loud
            # echo "... ${SUBKEYS}"
        done
    # If it is a normal field
    else
        # Remove if already existing
        sed -i "/$KEYS/ d" ${CONFIGSOURCE}
        # Store key
        KEYS=$(echo "${KEYS}=$(jq .$KEYS ${JSONSOURCE})")
        # Remove apostrophes
        KEYS=${KEYS//[\"\']/}
        # Write it in the config file
        echo $KEYS >>${CONFIGSOURCE}
        # Say it loud
        # echo "... ${KEYS}=$(jq .$KEYS ${JSONSOURCE})"
    fi
done

###########################
# Read all config options #
###########################

bashio::log.info "Starting the app with the variables in /config/enedisgateway2mqtt"

# For all keys in config file
for word in $(cat $CONFIGSOURCE); do
    # Data validation
    if [[ $word =~ ^.+[=].+$ ]]; then
        export $word # Export the variable
        bashio::log.blue "$word"
    else
        bashio::log.fatal "$word does not follow the structure KEY=text, it will be ignored and removed from the config"
        sed -i "/$word/ d" ${CONFIGSOURCE}
    fi
done

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
