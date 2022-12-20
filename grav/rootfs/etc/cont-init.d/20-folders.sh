#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

echo "Updating folders..."

for FOLDERS in "/share/grav" "/app/grav-admin/backup"; do
    echo "... $FOLDERS"
    mkdir -p $FOLDERS
    chown -R abc:abc $FOLDERS
done

bashio::log.warning "If error of missing folder when loading addon, just restart"
