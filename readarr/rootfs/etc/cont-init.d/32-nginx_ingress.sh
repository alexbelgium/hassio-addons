#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port

ingress_port=$(bashio::app.ingress_port)
ingress_interface=$(bashio::app.ip_address)
ingress_entry=$(bashio::app.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf

##################
# CONFIG SETTING #
##################

# Values
slug=readarr
CONFIG_LOCATION=/config/config.xml

# Before the config.xml guard: a fresh Readarr also starts without authentication
if [ "$(bashio::config "connection_mode")" = "ingress_noauth" ] && bashio::var.has_value "$(bashio::app.port 8787)"; then
    bashio::log.warning "SECURITY RISK: Readarr runs without authentication and port 8787 is published on host port $(bashio::app.port 8787)."
    bashio::log.warning "Anyone on your network can use it without logging in, change its settings, including download clients and API keys, and delete books."
    bashio::log.warning "Set connection_mode to ingress_auth and set a login in Readarr (Settings > General > Security, with Authentication Required set to Enabled, not disabled for local addresses), or disable the port in the add-on Network settings and use Ingress."
fi

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
