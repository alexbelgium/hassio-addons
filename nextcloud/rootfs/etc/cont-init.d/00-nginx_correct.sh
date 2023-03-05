#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Clean nginx files at each reboot
if [ -d /data/config/nginx ]; then
  rm -r /data/config/nginx
fi

# Prepare file
sed -i "/Strict-Transport-Security/d" /defaults/nginx/site-confs/default.conf.sample
# Delete end of file
sed -i '1h;1!H;$!d;g;s/\(.*\)}/\1/' /defaults/nginx/site-confs/default.conf.sample

# Append lines
cat /defaults/nginx_addition >> /defaults/nginx/site-confs/default.conf.sample
