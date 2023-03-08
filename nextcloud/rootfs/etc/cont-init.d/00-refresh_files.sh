#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Clean nginx files at each reboot
if [ -d /data/config/nginx ]; then
  rm -r /data/config/nginx
fi

# rm /data/config/crontabs
if [ -d /data/config/crontabs ]; then
  rm -r /data/config/crontabs
fi
