#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" >/etc/timezone
fi || (bashio::log.fatal "Error : $TIMEZONE not found. Here is a list of valid timezones : https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html")

#bashio::log.info "Generating self signed certificate"
#/./proxy keygen -s -C proxy -c goproxy
#
#echo " "
# Start app
if [ -f /config/goproxy.txt ]; then
    bashio::log.info "Starting app using the file in /addon_configs/xx-goproxy/goproxy.txt"
    /./proxy @/config/goproxy.txt
else
    bashio::log.warning "goproxy configuration file not existing, please create one in /addon_configs/xx-goproxy/goproxy.txt according to https://github.com/snail007/goproxy"
    sleep 500
fi
