#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015
set -e

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
fi || (bashio::log.fatal "Error : $TIMEZONE not found. Here is a list of valid timezones : https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html")

for env_var in CUSTOM_USER PASSWORD DRI_NODE DRINODE; do
    if bashio::config.has_value "${env_var}"; then
        bashio::log.info "Setting ${env_var} from add-on configuration"
        if [ -d /var/run/s6/container_environment ]; then
            printf "%s" "$(bashio::config "${env_var}")" > "/var/run/s6/container_environment/${env_var}"
        fi
    fi
done
