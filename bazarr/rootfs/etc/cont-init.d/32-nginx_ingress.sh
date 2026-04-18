#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

##################
# CONFIG SETTING #
##################

# Values
slug=bazarr
CONFIG_LOCATION=/config/config/config.yaml

if [ -f "$CONFIG_LOCATION" ]; then

    # Define addon mode
    connection_mode="$(bashio::config "connection_mode")"
    bashio::log.green "---------------------------"
    bashio::log.green "Connection_mode is $connection_mode"
    bashio::log.green "---------------------------"
    case "$connection_mode" in
        # Ingress mode, authentication is disabled
        ingress_noauth)
            bashio::log.green "Ingress is enabled, authentication is disabled"
            bashio::log.yellow "WARNING : Make sure that the port is not exposed externally by your router to avoid a security risk !"
            # Set base_url
            sed -i "s/  base_url:.*/  base_url: $slug/" "$CONFIG_LOCATION"
            # Disable auth
            sed -i '/^auth:/,/^[^ ]/{ s/  type:.*/  type: null/ }' "$CONFIG_LOCATION"
            ;;
        # Ingress mode, with authentication
        ingress_auth)
            bashio::log.green "Ingress is enabled, and external authentication is enabled"
            # Set base_url
            sed -i "s/  base_url:.*/  base_url: $slug/" "$CONFIG_LOCATION"
            ;;
        # No ingress mode, with authentication
        noingress_auth)
            bashio::log.green "Disabling ingress and enabling authentication"
            bashio::log.yellow "WARNING : Ingress is disabled so the app won't be available from HA itself !"
            sed -i "s/  base_url:.*/  base_url: ''/" "$CONFIG_LOCATION"
            ;;
    esac

fi
