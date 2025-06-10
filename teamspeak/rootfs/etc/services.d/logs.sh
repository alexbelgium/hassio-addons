#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ ! -f /touched ]; then
    until [[ -n $(cat /data/*_1.log 2> /dev/null) ]]; do
        sleep 1
  done
    bashio::log.info "Here are the admin informations:"
    cat /data/*_1.log
    touch /touched
    rm /etc/services.d/logs.sh
fi
