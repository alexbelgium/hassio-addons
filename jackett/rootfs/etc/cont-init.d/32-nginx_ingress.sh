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
slug=jackett
CONFIG_LOCATION=/config/addons_config/Jackett/ServerConfig.json

if [ -f "$CONFIG_LOCATION" ]; then

    # Define addon mode
    connection_mode="$(bashio::config "connection_mode")"
    bashio::log.green "---------------------------"
    bashio::log.green "Connection_mode is $connection_mode"
    bashio::log.green "---------------------------"
    case "$connection_mode" in
        # Ingress mode, authentification is disabled
        ingress_noauth)
            bashio::log.green "Ingress is enabled, authentification is disabled"
            bashio::log.yellow "WARNING : Make sure that the port is not exposed externally by your router to avoid a security risk !"
            sed -i -E "s/\"BasePathOverride\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"BasePathOverride\": \"${slug}\"/" "$CONFIG_LOCATION"
            sed -i -E "s/\"AdminPassword\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"AdminPassword\": \"\"/" "$CONFIG_LOCATION"
            ;;
        # Ingress mode, with authentification
        ingress_auth)
            bashio::log.green "Ingress is enabled, and external authentification is enabled"
            sed -i -E "s/\"BasePathOverride\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"BasePathOverride\": \"${slug}\"/" "$CONFIG_LOCATION"
            ;;
        # No ingress mode, with authentification
        noingress_auth)
            bashio::log.green "Disabling ingress and enabling authentification"
            bashio::log.yellow "WARNING : Ingress is disabled so the app won't be available from HA itself !"
            sed -i -E "s/\"BasePathOverride\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"BasePathOverride\": \"\"/" "$CONFIG_LOCATION"
            ;;
    esac

fi
