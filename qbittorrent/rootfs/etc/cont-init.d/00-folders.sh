#!/bin/bash

mkdir -p /config/addons_config/qBittorrent

if [ -f /config/addons_config/qBittorrent/qBittorrent.conf ]; then
    echo "Migrating previous folder"
    mkdir -p /config/addons_config/qbittorrent
    cp -prf /config/addons_config/qBittorrent/* /config/addons_config/qbittorrent/
    rm -r /config/addons_config/qBittorrent
    echo "Files were moved to /config/addons_config/qbittorrent" > /config/addons_config/qBittorrent/filesmoved
fi
