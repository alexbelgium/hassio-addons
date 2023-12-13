#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# if doesn't work, try UDP
if [ ! -f /data/tdp ]; then
  ping -c 1 1.1.1.1 &> /dev/null || ( bashio::log.warning "Can't connect, trying with TDP" && \
  touch /data/tdp && bashio::addon.restart )
else
  ping -c 1 1.1.1.1 &> /dev/null || ( bashio::log.warning "Can't connect even with TDP, reverting to default" && \
  rm /data/tdp && bashio::addon.restart )
fi
