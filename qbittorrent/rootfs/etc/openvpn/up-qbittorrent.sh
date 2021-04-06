#!/usr/bin/with-contenv bash

WEBUI_PORT=${WEBUI_PORT:-8080}

if [ -n "${UMASK_SET}" ] && [ -z "${UMASK}" ]; then
  echo -e "You are using a legacy method of defining umask\nplease update your environment variable from UMASK_SET to UMASK\nto keep the functionality after July 2021"
  umask ${UMASK_SET}
fi

declare CONFIG
CONFIG=$(</config/qBittorrent/qBittorrent.conf)
CONFIG=$(bashio::jq "${CONFIG}" ".\"bind-address-ipv4\"=\"${1}\"")
echo "${CONFIG}" > /config/qBittorrent/qBittorrent.conf

exec /usr/bin/transmission-daemon --foreground --config-dir /data/transmission
