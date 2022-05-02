#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi

bashio::log.info "Default username:password is admin:admin123"
