#!/usr/bin/env bashio

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
        VALUES=$(jq .$KEYS ${JSONSOURCE})
        for SUBKEYS in ${VALUES//,/ }; do
            [[ ! $SUBKEYS =~ ^.+[=].+$ ]] && bashio::log.fatal "Your custom_var field does not follow the structure KEY=\"text\",KEY2=\"text2\" it will be ignored" && continue || true
            # Remove the key if already existing
            sed -i "/$(echo "${SUBKEYS%%=*}")/ d" ${CONFIGSOURCE} &>/dev/null || true
            # Write it in the config file
            echo ${SUBKEYS} >>${CONFIGSOURCE}
            # Say it loud
            echo "... ${SUBKEYS}"
        done
    # If it is a normal field
    else
        # Remove if already existing
        sed -i "/$KEYS/ d" ${CONFIGSOURCE} &>/dev/null || true
        # Write it in the config file
        echo "${KEYS}=$(jq .$KEYS ${JSONSOURCE})" >>${CONFIGSOURCE}
        # Say it loud
        echo "... ${KEYS}=$(jq .$KEYS ${JSONSOURCE})"
    fi
done

###########################
# Read all config options #
###########################

# Replace all "" with ''
sed -i 's|"|'\''|g' $CONFIGSOURCE

# For all keys in config file
for word in $(cat $CONFIGSOURCE); do
    [[ ! $word =~ ^.+[=].+$ ]] && bashio::log.fatal "$word does not follow the structure KEY=\'text\', it will be ignored" || true
    export "$word" # Export the variable
    echo "$word"
done

##############
# Launch App #
##############
echo " "
bashio::log.info "Starting the app"
echo " "

python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
