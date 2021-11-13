#!/usr/bin/env bashio

#################
# Create config #
#################

# Create the config file
mkdir -p /config/enedisgateway2mqtt
touch /config/enedisgateway2mqtt/enedisgateway2mqtt.conf

# Read the config file

#################
# Create config #
#################
echo " "
bashio::log.info "Setting variables"
echo " "
for VARIABLES in "ACCESS_TOKEN" "PDL" "MQTT_HOST" "MQTT_PORT" "MQTT_PREFIX" "MQTT_CLIENT_ID" "MQTT_USERNAME" "MQTT_PASSWORD" "RETAIN" "QOS" "GET_CONSUMPTION" "GET_PRODUCTION" "HA_AUTODISCOVERY" "HA_AUTODISCOVERY_PREFIX" "CONSUMPTION_PRICE_BASE" "CONSUMPTION_PRICE_HC" "CONSUMPTION_PRICE_HP" "CARD_MYENEDIS"; do
    if bashio::config.has_value $VARIABLES; then
        export $VARIABLES=$(bashio::config $VARIABLES)
        echo "$VARIABLES set to $(bashio::config $VARIABLES)"
    fi
done
echo " "
bashio::log.info "Starting the app"
echo " "

##############
# Launch App #
##############
python -u /app/main.py || bashio::log.fatal "The app has crashed. Are you sure you entered the correct config options?"
