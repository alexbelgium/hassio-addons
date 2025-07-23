#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

mkdir -p /config/qBittorrent
mkdir -p /config/wireguard
mkdir -p /config/openvpn

MIGRATED=""

# Move main folder
if [ -f /homeassistant/addons_config/qBittorrent/qBittorrent.conf ] && [ ! -f /homeassistant/addons_config/qBittorrent/migrated ]; then
    bashio::log.warning "----------------------------------------"
    bashio::log.warning "Migrating configuration to the new addon"
    bashio::log.warning "----------------------------------------"
    cp -rnp /homeassistant/addons_config/qBittorrent/* /config/qBittorrent/ &> /dev/null || true
    if [ -d /config/qBittorrent/addons_config ]; then rm -r /config/qBittorrent/addons_config; fi
    if [ -d /config/qBittorrent/qBittorrent ]; then rm -r /config/qBittorrent/qBittorrent; fi
    echo "Files moved to /addon_configs/$HOSTNAME/openvpn" > /homeassistant/addons_config/qBittorrent/migrated
    bashio::log.yellow "... moved files from /config/addons_config/qBittorrent to /addon_configs/$HOSTNAME/qBitorrent (must be accessed with my Filebrowser addon)"
    MIGRATED=true
fi

# Move config
if [ -f /config/qBittorrent/config/qBittorrent.conf ]; then
    mv /config/qBittorrent/config/* /config/qBittorrent/ || true
    mv /config/qBittorrent/data/* /config/qBittorrent/ || true
    rm -r /config/qBittorrent/config || true
    rm -r /config/qBittorrent/data || true
    MIGRATED=true
fi

# Move openvpn
if [ -d /homeassistant/openvpn ]; then
    if [ ! -f /homeassistant/openvpn/migrated ] && [ "$(ls -A /homeassistant/openvpn)" ]; then
        cp -rnf /homeassistant/openvpn/* /config/openvpn &> /dev/null || true
        echo "Files moved to /addon_configs/$HOSTNAME/openvpn" > /homeassistant/openvpn/migrated
    fi
fi

# Move config.yaml
if [ -f /homeassistant/addons_config/qbittorrent/config.yaml ] && [ ! -f /homeassistant/addons_config/qbittorrent/migrated ]; then
    cp -rnf /homeassistant/addons_config/qbittorrent/* /config/ &> /dev/null || true
    rm -r /homeassistant/addons_config/qbittorrent
    bashio::log.yellow "... moved config.yaml from /config/addons_config/qbittorrent to /addon_configs/$HOSTNAME"
fi

# Move autoscript
if [ -f /homeassistant/addons_autoscrips/qbittorrent.sh ]; then
    cp -rnf /homeassistant/addons_autoscrips/qbittorrent.sh /config/ &> /dev/null || true
    mv /homeassistant/addons_autoscrips/qbittorrent.sh /homeassistant/addons_autoscrips/qbittorrent.sh.bak
    bashio::log.yellow "... moved qbittorrent.sh from /config/addons_autoscripts to /addon_configs/$HOSTNAME"
fi

# Reboot post migration
if [[ "$MIGRATED" == "true" ]]; then
    bashio::log.warning "Options were changed, restarting the addon"
    sleep 5
    bashio::addon.restart
fi
