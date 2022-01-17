#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

WEBUI_PORT=${WEBUI_PORT:-8080}

exec s6-setuidgid abc /usr/bin/qbittorrent-nox --webui-port="${WEBUI_PORT}"
