#!/bin/bash

mkdir -p /config/addons_config/qBittorrent

if [ -f /config/qBittorrent/qBittorrent.conf ]; then
    echo "Migrating previous folder"
    cp -prf /config/qBittorrent/* /config/addons_config/qBittorrent/
    rm -r /config/qBittorrent/*
    echo "Files were moved to /config/addons_config/qBittorrent" > /config/qBittorrent/filesmoved
fi
