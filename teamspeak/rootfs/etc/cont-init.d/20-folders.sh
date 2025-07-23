#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Data remanence for /teamspeak/save
if [ -d /teamspeak ]; then
    cp -rn /teamspeak/* /data
    rm -r /teamspeak
    ln -sf /data /teamspeak
    chmod -R 777 /teamspeak
fi

#chown -R PUID:PGID /data
chmod -R 777 /data
