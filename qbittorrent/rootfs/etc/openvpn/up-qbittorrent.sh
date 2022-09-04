#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

WEBUI_PORT=${WEBUI_PORT:-8080}

s6-notifyoncheck -d -n 12 -c "nc -z 127.0.0.1 ${WEBUI_PORT}" \ 
        s6-setuidgid abc /usr/bin/qbittorrent-nox --webui-port="${WEBUI_PORT}"
