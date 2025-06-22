#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

WEBUI_PORT=${WEBUI_PORT:-8080}

exec \
	s6-notifyoncheck -d -n 300 -w 1000 -c "nc -z localhost ${WEBUI_PORT}" \
	s6-setuidgid abc /usr/bin/qbittorrent-nox --webui-port="${WEBUI_PORT}"
