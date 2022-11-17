#!/bin/bash

mkdir -p /config/addons_config/qBittorrent

if [ -f /config/addons_config/qbittorrent/qBittorrent.conf ] && [ -f /config/addons_config/qBittorrent/qBittorrent.conf ]; then
echo "Restore folders"
mv /config/addons_config/qBittorrent /config/addons_config/qBittorrent_old
mv /config/addons_config/qbittorrent /config/addons_config/qBittorrent
fi
