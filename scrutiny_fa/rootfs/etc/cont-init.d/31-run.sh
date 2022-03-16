#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#######################
# Require unprotected #
#######################

bashio::require.unprotected

##############
# Data usage #
##############

bashio::log.info "Setting permissions"
chown -R abc:abc /data

#######################
# VIEWPORT CORRECTION #
#######################

# correct viewport bug
# grep -rl '"lt-md":"(max-width:  959px)"' /app | xargs sed -i 's|"lt-md":"(max-width:  959px)"|"lt-md":"(max-width:  100px)"|g' || true

######################
# API URL CORRECTION #
######################

# allow true url for ingress
grep -rl '/api/' /app | xargs sed -i 's|/api/|api/|g' || true
grep -rl 'api/' /app | xargs sed -i 's|api/|./api/|g' || true

################
# CRON OPTIONS #
################

rm /config/crontabs/* || true
sed -i '$d' /etc/crontabs/root
sed -i -e '$a @reboot /run.sh' /etc/crontabs/root

# Align update with options
FREQUENCY=$(bashio::config 'Updates')
bashio::log.info "$FREQUENCY updates"

case $FREQUENCY in
    "Hourly")
        sed -i -e '$a 0 * * * * /run.sh' /etc/crontabs/root
        ;;

    "Daily")
        sed -i -e '$a 0 0 * * * /run.sh' /etc/crontabs/root
        ;;

    "Weekly")
        sed -i -e '$a 0 0 * * 0 /run.sh' /etc/crontabs/root
        ;;
esac
