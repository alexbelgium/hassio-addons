#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Clean nginx files at each reboot
for folders in /data/config/nginx /data/config/crontabs /data/config/logs; do
  if [ -d "$folders" ]; then rm -r "$folders"; fi
done

# Make links between logs and docker
for logfile in /data/config/log/nginx/error.log /data/config/log/nginx/access.log /data/config/log/php/error.log /data/config/log/nextcloud.log; do
  # Make sure directory exists
  mkdir -p "$(dirname "$logfile")"
  # Clean files
  if [ -f "$logfile" ]; then rm -r "$logfile"; fi
  # Create symlink
  ln -sf /proc/1/fd/1 "$logfile"
done
