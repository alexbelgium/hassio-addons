#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Data remanence for /teamspeak/save
if [ -d /teamspeak/save ]; then
    cp -rn /teamspeak/save/* /data
    rm -r /teamspeak/save
fi
mkdir -p /teamspeak
ln -sf /data /teamspeak/save
#chown -R PUID:GUID /data
chmod -R 777 /data
#chown -R PUID:GUID /data
chmod -R 777 /teamspeak
