#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

if [ -d /config/filebrowser ]; then
    echo "Moving to new location /config/addons_config/filebrowser"
    mkdir -p /config/addons_config/filebrowser
    chmod 777 /config/addons_config/filebrowser
    mv /config/filebrowser/* /config/addons_config/filebrowser/
    rm -r /config/filebrowser
fi

if [ ! -d /config/addons_config/filebrowser ]; then
    echo "Creating /config/addons_config/filebrowser"
    mkdir -p /config/addons_config/filebrowser
    chmod 777 /config/addons_config/filebrowser
fi
