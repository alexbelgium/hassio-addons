#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015
set -e

# Set TZ
if bashio::config.has_value 'TZ'; then
  TIMEZONE=$(bashio::config 'TZ')
  bashio::log.info "Setting timezone to $TIMEZONE"
  ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi

bashio::log.info "Install libnss3"
apt-get update && apt-get install libnss3 &>/dev/null

# Set Ingress login
if [ ! -f /config/app.db ]; then
  bashio::log.warning "First boot : disabling Ingress until addon restart"
else
  sqlite3 /config/app.db 'update settings set config_reverse_proxy_login_header_name="X-WebAuth-User",config_allow_reverse_proxy_header_login=1'
fi

bashio::log.info "Default username:password is admin:admin123"
