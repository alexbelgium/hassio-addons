#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

#################
# CONFIG IMPORT #
#################

if [ "$(ls -A "$CONFIGSOURCE/configurations")" ]; then
    bashio::log.info "Configurations were found in $CONFIGSOURCE/configurations, they will be loaded."
    JSON_CONFIGURATION_DIR="$CONFIGSOURCE/configurations"
    export JSON_CONFIGURATION_DIR
    chown -R www-data:www-data "$CONFIGSOURCE"
fi

# Allow config dir
export IMPORT_DIR_ALLOWLIST="$CONFIGSOURCE"
export IMPORT_DIR_WHITELIST="${CONFIGSOURCE}/import_files"

# shellcheck disable=SC2155
export AUTO_IMPORT_SECRET="$(bashio::config "AUTO_IMPORT_SECRET")"
# shellcheck disable=SC2155
export CAN_POST_FILES="$(bashio::config "CAN_POST_FILES")"
# shellcheck disable=SC2155
export CAN_POST_AUTOIMPORT="$(bashio::config "CAN_POST_AUTOIMPORT")"

################
# CRON OPTIONS #
################

if bashio::config.has_value 'Updates'; then

    # Align update with options
    echo ""
    FREQUENCY=$(bashio::config 'Updates')
    bashio::log.info "$FREQUENCY updates"
    echo ""

    # Sets cron // do not delete this message
    cp /templates/cronupdate /etc/cron."${FREQUENCY}"/
    chmod 777 /etc/cron."${FREQUENCY}"/cronupdate

    # Sets cron to run with www-data user
    # sed -i 's|root|www-data|g' /etc/crontab

    # Starts cron
    service cron start

    # Export variables
    IMPORT_DIR_WHITELIST="${CONFIGSOURCE}/import_files"
    export IMPORT_DIR_WHITELIST

    bashio::log.info "Automatic updates were requested. The files in ${CONFIGSOURCE}/import_files will be imported $FREQUENCY."

    if [ ! "$(ls -A "${CONFIGSOURCE}"/import_files)" ]; then
        bashio::log.fatal "Automatic updates were requested, but there are no configuration files in ${CONFIGSOURCE}/import_files. There will therefore be be no automatic updates."
        true
    fi

else

    bashio::log.info "Automatic updates not set in addon config. If you add configuration files in ${CONFIGSOURCE}/import_files, they won't be automatically updated."

fi

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"

cd /var/www/html || true
if bashio::config.true 'silent'; then
    bashio::log.warning "Silent mode activated. Only errors will be shown. Please disable in addon options if you need to debug"
    sudo -E su - www-data -s /bin/bash -c 'cd /var/www/html && /./usr/local/bin/entrypoint.sh' >/dev/null
else
    sudo -E su - www-data -s /bin/bash -c 'cd /var/www/html && /./usr/local/bin/entrypoint.sh'
fi
