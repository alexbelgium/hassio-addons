#!/bin/bash

if [ ! -d /share/storage/tv ]; then
    echo "Creating /share/storage/tv"
    mkdir -p /share/storage/tv
    chown -R abc:abc /share/storage/tv
fi

if [ ! -d /share/downloads ]; then
    echo "Creating /share/downloads"
    mkdir -p /share/downloads
    chown -R abc:abc /share/downloads
fi

if [ -d /config/sonarr ] && [ ! -d /config/addons_config/sonarr ]; then
    echo "Moving to new location /config/addons_config/sonarr"
    mkdir -p /config/addons_config/sonarr
    chown -R abc:abc /config/addons_config/sonarr
    mv /config/sonarr/* /config/addons_config/sonarr/
    rm -r /config/sonarr
fi

if [ ! -d /config/addons_config/sonarr ]; then
    echo "Creating /config/addons_config/sonarr"
    mkdir -p /config/addons_config/sonarr
    chown -R abc:abc /config/addons_config/sonarr
fi
