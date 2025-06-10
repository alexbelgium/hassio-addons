#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Avoid unbound variables
set +u

# Autodefine if not defined
if [ -n "$INTERFACE_NAME" ]; then
  # shellcheck disable=SC2155
  export INTERFACE_NAME="$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')"
  bashio::log.blue "Autodetection : INTERFACE_NAME=$INTERFACE_NAME"
fi

bashio::log.info "Starting..."
/usr/bin/python3 /opt/arpspoof/arpspoof.py
