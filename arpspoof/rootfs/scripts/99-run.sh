#!/usr/bin/env bashio

# Autodefine if not defined
if [ -z INTERFACE_NAME ]; then
INTERFACE_NAME=$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')
bashio::log.blue "Autodetection : INTERFACE_NAME=$INTERFACE_NAME"
fi

bashio::log.info "Starting..."
/usr/bin/python3 /opt/arpspoof/arpspoof.py
