#!/usr/bin/env bashio
# shellcheck shell=bash

#################
# NGINX SETTING #
#################

# declare port
# declare certfile
declare ingress_interface
declare ingress_port
# declare keyfile

CLOUDCMD_PREFIX=$(bashio::addon.ingress_entry)
export CLOUDCMD_PREFIX

declare ADDON_PROTOCOL=http
if bashio::config.true 'ssl'; then
    ADDON_PROTOCOL=https
    bashio::config.require.ssl
fi

# port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${CLOUDCMD_PREFIX}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
    CUSTOMOPTIONS=" $(bashio::config 'CUSTOM_OPTIONS')"
else
    CUSTOMOPTIONS=""
fi

if bashio::config.has_value 'DROPBOX_TOKEN'; then
    DROPBOX_TOKEN="--dropbox --dropbox-token $(bashio::config 'DROPBOX_TOKEN')"
else
    DROPBOX_TOKEN=""
fi

bashio::log.info "Starting..."

cd /
./usr/src/app/bin/cloudcmd.mjs '"'"$DROPBOX_TOKEN""$CUSTOMOPTIONS"'"' &
bashio::net.wait_for 8000 localhost 900 || true
bashio::log.info "Started !"
exec nginx
