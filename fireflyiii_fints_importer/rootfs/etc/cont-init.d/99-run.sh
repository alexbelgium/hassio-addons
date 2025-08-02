#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config/addons_config/fireflyiii_fints_importer"

#################
# CONFIG IMPORT #
#################

if [ "$(ls -A "$CONFIGSOURCE")" ]; then
    bashio::log.info "Configurations were found in $CONFIGSOURCE, they will be loaded."
else
    bashio::log.warning "No configurations in $CONFIGSOURCE, you'll need to input the infos manually."
fi

################
# CRON OPTIONS #
################

if bashio::config.has_value 'Updates'; then

    if [ "$(ls -A "${CONFIGSOURCE}")" ]; then

        # Align update with options
        echo ""
        FREQUENCY=$(bashio::config 'Updates')
        bashio::log.info "$FREQUENCY updates"
        echo ""

        for i in $(seq 4 2 12); do
            hour="   $i"
            freqDir="/etc/periodic/daily$i"
            echo "0    ${hour:(-4)}       *       *       *       run-parts \"$freqDir\"" >> /etc/crontabs/root
            mkdir "$freqDir"
        done

        # Sets cron // do not delete this message
        freqDir="/etc/periodic/${FREQUENCY}"
        cp /templates/cronupdate "$freqDir/"
        chmod 755 "$freqDir/cronupdate"

        # Sets cron to run with www-data user
        # sed -i 's|root|www-data|g' /etc/crontab

        # Starts cron
        echo "Timezone $TZ"
        export TZ
        crond -l 2 -f > /dev/stdout 2> /dev/stderr &

        # Export variables
        IMPORT_DIR_WHITELIST="${CONFIGSOURCE}/import_files"
        export IMPORT_DIR_WHITELIST

        bashio::log.info "Automatic updates were requested. The files in ${CONFIGSOURCE} will be imported $FREQUENCY."

    else
        bashio::log.fatal "Automatic updates were requested, but there are no configuration files in ${CONFIGSOURCE}. There will therefore be be no automatic updates."
    fi

fi

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"

if bashio::config.true 'silent'; then
    bashio::log.warning "Silent mode activated. Only errors will be shown. Please disable in addon options if you need to debug"
    php -S 0.0.0.0:8080 /app/index.php > /dev/null
else
    php -S 0.0.0.0:8080 /app/index.php
fi
