#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi || true

# Set keyboard
if bashio::config.has_value 'KEYBOARD'; then
    KEYBOARD=$(bashio::config 'KEYBOARD')
    bashio::log.info "Setting keyboard to $KEYBOARD"
    sed -i "1a export KEYBOARD=$KEYBOARD" /etc/s6-overlay/s6-rc.d/svc-web/run
    if [ -d /var/run/s6/container_environment ]; then printf "$KEYBOARD" > /var/run/s6/container_environment/KEYBOARD; fi
fi || true

# Set cli args
if bashio::config.has_value 'CLI_ARGS'; then
    bashio::log.info "Setting password to the value defined in options"
    CLI_ARGS=$(bashio::config 'CLI_ARGS')
    bashio::log.info "Setting arguments to $CLI_ARGS"
    sed -i "1a export CLI_ARGS=$CLI_ARGS" /etc/s6-overlay/s6-rc.d/svc-web/run
    if [ -d /var/run/s6/container_environment ]; then printf "$CLI_ARGS" > /var/run/s6/container_environment/CLI_ARGS; fi
fi || true

# Set password
if bashio::config.has_value 'PASSWORD'; then
    bashio::log.info "Setting password to the value defined in options"
    PASSWORD=$(bashio::config 'PASSWORD')
    bashio::log.info "Setting password to $PASSWORD"
    sed -i "1a export PASSWORD=$PASSWORD" /etc/s6-overlay/s6-rc.d/svc-web/run
    if [ -d /var/run/s6/container_environment ]; then printf "$PASSWORD" > /var/run/s6/container_environment/PASSWORD; fi
fi || true
