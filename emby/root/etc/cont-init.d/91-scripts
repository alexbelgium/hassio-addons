#!/usr/bin/with-contenv bashio

###############
# SILENT MODE #
###############

if bashio::config.true 'silent'; then
APPEND=' > /dev/null'
sed -i '$s|$|'"$APPEND"'|' /etc/services.d/emby/run
bashio::log.info 'Silent mode activated, all logs from emby server are hidden. Disable this option if you need to troubleshoot emby.'
fi
