#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# SILENT MODE #
###############

if bashio::config.true 'silent'; then
  APPEND=' >/dev/null'
  sed -i '$s|$|'"$APPEND"'|' /etc/s6-overlay/s6-rc.d/svc-emby/run
  bashio::log.info 'Silent mode activated, all logs from emby server are hidden. Disable this option if you need to troubleshoot the addon.'
fi
