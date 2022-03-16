#!/bin/bash

if [ ! -d /share/downloads ]; then
    echo "Creating /share/downloads"
    mkdir -p /share/downloads
    chown -R abc:abc /share/downloads
fi

if [ -d /config/Jackett ] && [ ! -d /config/addons_config/Jackett ]; then
    echo "Moving to new location /config/addons_config/Jackett"
    mkdir -p /config/addons_config/Jackett
    chown -R abc:abc /config/addons_config/Jackett
    mv /config/Jackett/* /config/addons_config/Jackett/
    rm -r /config/Jackett
    rm -r /config/jackett
fi

if [ ! -d /config/addons_config/Jackett ]; then
    echo "Creating /config/addons_config/Jackett"
    mkdir -p /config/addons_config/Jackett
    chown -R abc:abc /config/addons_config/Jackett
fi
