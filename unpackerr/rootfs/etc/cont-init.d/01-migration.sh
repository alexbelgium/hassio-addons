#!/usr/bin/bashio

if [ -f /homeassistant/unpackerr.conf ]; then
    bashio::log.warning "Migrating unpackerr.conf to /addons_configs/$HOSTNAME/unpackerr.conf"
    mv /homeassistant/unpackerr.conf /config/unpackerr.conf
fi