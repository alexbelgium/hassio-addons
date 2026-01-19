#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################
declare ingress_interface
declare ingress_port
declare ingress_entry

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
CONFIG_LOCATION="/config/addons_config/Jackett/ServerConfig.json"

if [ -f "$CONFIG_LOCATION" ]; then
    connection_mode="$(bashio::config "connection_mode")"
    bashio::log.green "---------------------------"
    bashio::log.green "Connection_mode is $connection_mode"
    bashio::log.green "---------------------------"
    case "$connection_mode" in
        ingress_noauth|ingress_auth)
            base_path="$slug"
            ;;
        noingress_auth)
            base_path=""
            ;;
    esac

    if command -v jq >/dev/null 2>&1; then
        tmp_config="$(mktemp)"
        jq --arg basepath "$base_path" '.BasePathOverride = $basepath' "$CONFIG_LOCATION" > "$tmp_config"
        mv "$tmp_config" "$CONFIG_LOCATION"
    else
        bashio::log.warning "jq not available; skipping BasePathOverride update"
    fi
fi
