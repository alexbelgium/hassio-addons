#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

DASHBOARD_PORT=$(bashio::config 'dashboard_port')

if bashio::config.true 'enable_dashboard'; then
    if [[ -f /etc/nginx/http.d/default.conf ]]; then
        sed -i "s/listen 80 default_server;/listen ${DASHBOARD_PORT} default_server;/" /etc/nginx/http.d/default.conf
        sed -i "s/listen \[::\]:80 default_server;/listen [::]:${DASHBOARD_PORT} default_server;/" /etc/nginx/http.d/default.conf
    elif [[ -f /etc/nginx/conf.d/default.conf ]]; then
        sed -i "s/listen 80 default_server;/listen ${DASHBOARD_PORT} default_server;/" /etc/nginx/conf.d/default.conf
        sed -i "s/listen \[::\]:80 default_server;/listen [::]:${DASHBOARD_PORT} default_server;/" /etc/nginx/conf.d/default.conf
    fi
fi
