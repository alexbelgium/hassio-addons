#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi

# Set keyboard
if bashio::config.has_value 'KEYBOARD'; then
    KEYBOARD=$(bashio::config 'KEYBOARD')
    bashio::log.info "Setting keyboard to $KEYBOARD"
    sed -i "1a export KEYBOARD=$KEYBOARD" /etc/services.d/web/run
fi

# Set cli args
if bashio::config.has_value 'CLI_ARGS'; then
    bashio::log.info "Setting password to the value defined in options"
    CLI_ARGS=$(bashio::config 'CLI_ARGS')
    bashio::log.info "Setting arguments to $CLI_ARGS"
    sed -i "1a export CLI_ARGS=$CLI_ARGS" /etc/services.d/web/run
fi

# Set password
if bashio::config.has_value 'PASSWORD'; then
    bashio::log.info "Setting password to the value defined in options"
    PASSWORD=$(bashio::config 'PASSWORD')
    bashio::log.info "Setting password to $PASSWORD"
    sed -i "1a export PASSWORD=$PASSWORD" /etc/services.d/web/run
fi
