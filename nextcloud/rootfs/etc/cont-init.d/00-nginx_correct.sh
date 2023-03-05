#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Clean nginx files at each reboot
if [ -d /data/config/nginx ]; then
  rm -r /data/config/nginx
fi

# Prepare file
sed -i "/Strict-Transport-Security/d" /nginx/site-confs/default.conf.sample
sed -i '$d' /nginx/site-confs/default.conf.sample

# Append lines
cat /defaults/nginx_addition >> /nginx/site-confs/default.conf.sample
