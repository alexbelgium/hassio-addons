#!/usr/bin/env bashio

INTERFACE_NAME=$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')
bashio::log.blue "INTERFACE_NAME=$INTERFACE_NAME"

bashio::log.info "Starting..."
/usr/bin/python3 /opt/arpspoof/arpspoof.py
