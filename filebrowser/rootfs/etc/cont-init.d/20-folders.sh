#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -f /config/addons_config/filebrowser/filebrowser.d* ]; then
    echo "Moving database to new location /config"
    mkdir -p /config
    chmod 777 /config
    mv /config/addons_config/filebrowser/* /config/
    rm -r /config/addons_config/filebrowser
fi
