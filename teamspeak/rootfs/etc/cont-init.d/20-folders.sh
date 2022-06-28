#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Data remanence for /teamspeak/save
if [ -d /teamspeak ]; then
    cp -rn /teamspeak/* /data
    rm -r /teamspeak
    ln -sf /data /teamspeak
    chmod -R 777 /teamspeak
fi

#chown -R PUID:GUID /data
chmod -R 777 /data
