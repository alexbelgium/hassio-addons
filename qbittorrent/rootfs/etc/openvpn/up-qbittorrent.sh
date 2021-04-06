#!/usr/bin/with-contenv bashio

WEBUI_PORT=${WEBUI_PORT:-8080}

exec s6-setuidgid abc /usr/bin/qbittorrent-nox --webui-port="${WEBUI_PORT}"
