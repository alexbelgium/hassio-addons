#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Create new folders
mkdir -p /config/wireguard
mkdir -p /config/openvpn
mkdir -p /config/qBittorrent/config
mkdir -p /config/qBittorrent/data

if [ -f /homeassistant/addons_config/qBittorrent/qBittorrent.conf ]; then
    bashio::log.warning "----------------------------------------"
    bashio::log.warning "Migrating configuration to the new addon"
    bashio::log.warning "----------------------------------------"
    mv /homeassistant/addons_config/qBittorrent/*.json /config/qBittorrent/config/
    mv /homeassistant/addons_config/qBittorrent/*.conf /config/qBittorrent/config/
    if [ -d /homeassistant/addons_config/qBittorrent/rss ]; then mv /homeassistant/addons_config/qBittorrent/rss /config/qBittorrent/config/; fi
    mv /homeassistant/addons_config/qBittorrent/* /config/qBittorrent/data/
    if [ -d /config/qBittorrent/data/addons_config ]; then rm -r /config/qBittorrent/data/addons_config; fi
    if [ -d /config/qBittorrent/data/qBittorrent ]; then rm -r /config/qBittorrent/data/qBittorrent; fi
    rm -r /homeassistant/addons_config/qBittorrent
    bashio::log.yellow "... moved files from /config/addons_config/qBittorrent to /addon_configs/$HOSTNAME/qBitorrent (must be accessed with my Filebrowser addon)"
fi || true

if [ -d /homeassistant/openvpn ]; then
    if [ "$(ls -A /homeassistant/openvpn)" ]; then
        mv /homeassistant/openvpn/* /config/openvpn/
        rm -r /homeassistant/openvpn
        bashio::log.yellow "... moved files from /config/openvpn to /addon_configs/$HOSTNAME/openvpn"
    fi
fi || true

if [ -f /homeassistant/addons_config/qbittorrent/config.yaml ]; then
    mv /homeassistant/addons_config/qbittorrent/* /config/
    rm -r /homeassistant/addons_config/qbittorrent
    bashio::log.yellow "... moved config.yaml from /config/addons_config/qbittorrent to /addon_configs/$HOSTNAME"
fi || true

if [ -f /homeassistant/addons_autoscrips/qbittorrent.sh ]; then
    mv /homeassistant/addons_autoscrips/qbittorrent.sh /config/
    bashio::log.yellow "... moved qbittorrent.sh from /config/addons_autoscripts to /addon_configs/$HOSTNAME"
fi || true

if bashio::config.has_value 'openvpn_enable'; then
    if bashio::config.true 'openvpn_enabled'; then
        bashio::addon.option "VPN_ENABLED" "yes"
        bashio::log.yellow "... openvpn_enable : was true, VPN_ENABLED set to yes"
        bashio::addon.option "VPN_TYPE" "openvpn"
        bashio::log.yellow "... openvpn_enable : was true, VPN_TYPE set to openvpn"
    fi
    bashio::addon.option "openvpn_enable"
    bashio::log.yellow "... openvpn_enable : removed as not used anymore"
fi || true

if bashio::config.has_value 'openvpn_username'; then
    bashio::addon.option "VPN_USERNAME" "$(bashio::config "openvpn_username")"
    bashio::log.yellow "... openvpn_username : was set, VPN_USERNAME set to $(bashio::config "openvpn_username")"
    bashio::addon.option "openvpn_username"
    bashio::log.yellow "... openvpn_username : removed as not used anymore"
fi || true

if bashio::config.has_value 'Username'; then
    bashio::addon.option "QBT_USERNAME" "$(bashio::config "Username")"
    bashio::log.yellow "... Username : was set, QBT_USERNAME set to $(bashio::config "Username")"
    bashio::addon.option "Username"
    bashio::log.yellow "... Username : removed as not used anymore"
fi || true

if bashio::config.has_value 'openvpn_password'; then
    bashio::addon.option "VPN_PASSWORD" "$(bashio::config "openvpn_password")"
    bashio::log.yellow "... openvpn_password : was set, VPN_PASSWORD set to $(bashio::config "openvpn_password")"
    bashio::addon.option "openvpn_password"
    bashio::log.yellow "... openvpn_password : removed as not used anymore"
fi  || true

if bashio::config.has_value 'whitelist'; then
    bashio::addon.option "LAN_NETWORK" "$(bashio::config "whitelist")"
    bashio::log.yellow "... whitelist : was set, LAN_NETWORK set to $(bashio::config "whitelist")"
    bashio::addon.option "whitelist"
    bashio::log.yellow "... whitelist : removed as not used anymore"
fi || true

if bashio::config.has_value 'smbv1'; then
    bashio::addon.option "smbv1"
    bashio::log.yellow "... smbv1 : removed as not used anymore"
fi || true

if bashio::config.has_value 'openvpn_config'; then
    openvpn_config="$(bashio::config "openvpn_config")"
    if [ -f "$openvpn_config" ]; then
        mv "$openvpn_config" /config/openvpn/
    fi
fi || true

if [ -d /config/qBittorrent/qBittorrent ]; then
rm -r /config/qBittorrent/qBittorrent
fi || true
