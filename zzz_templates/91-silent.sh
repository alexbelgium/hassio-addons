#!/usr/bin/with-contenv bashio

###############
# SILENT MODE #
###############

if bashio::config.true 'silent'; then
APPEND=' > /dev/null'
[ -f /etc/services.d/*/run ] && sed -i '$s|$|'"$APPEND"'|' /etc/services.d/*/run
[ -f /etc/cont-init.d/*/*run* ] && sed -i '$s|$|'"$APPEND"'|' /etc/cont-init.d/*/*run*
bashio::log.info 'Silent mode activated, all logs from emby server are hidden. Disable this option if you need to troubleshoot the addon.'
fi
