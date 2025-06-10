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
slug=radarr
CONFIG_LOCATION=/config/addons_config/"$slug"/config.xml

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
            # Define UrlBase
            sed -i "/UrlBase/d" "$CONFIG_LOCATION"
            sed -i "2a <UrlBase>$slug<\/UrlBase>" "$CONFIG_LOCATION"
            # Disable local auth
            sed -i "/AuthenticationType/d" "$CONFIG_LOCATION"
            sed -i "2a <AuthenticationType>DisabledForLocalAddresses</AuthenticationType>" "$CONFIG_LOCATION"
            # Disable local auth
            sed -i "/AuthenticationMethod/d" "$CONFIG_LOCATION"
            sed -i "2a <AuthenticationMethod>external</AuthenticationMethod>" "$CONFIG_LOCATION"
            ;;
        # Ingress mode, with authentification
        ingress_auth)
            bashio::log.green "Ingress is enabled, and external authentification is enabled"
            # Define UrlBase
            sed -i "/UrlBase/d" "$CONFIG_LOCATION"
            sed -i "2a <UrlBase>$slug<\/UrlBase>" "$CONFIG_LOCATION"
            sed -i "/<AuthenticationMethod>external/d" "$CONFIG_LOCATION"
            ;;
        # No ingress mode, with authentification
        noingress_auth)
            bashio::log.green "Disabling ingress and enabling authentification"
            bashio::log.yellow "WARNING : Ingress is disabled so the app won't be available from HA itself !"
            sed -i "/UrlBase/d" "$CONFIG_LOCATION"
            sed -i "/<AuthenticationMethod>external/d" "$CONFIG_LOCATION"
            ;;
  esac

fi
