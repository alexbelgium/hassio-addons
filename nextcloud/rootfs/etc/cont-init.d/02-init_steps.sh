#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Clean nginx files at each reboot
echo "Cleaning files"
for var in /data/config/nginx /data/config/crontabs /data/config/logs; do
  if [ -d "$var" ]; then rm -r "$var"; fi
done

# Make links between logs and docker
echo "Setting logs"
for var in /data/config/log/nginx/error.log /data/config/log/nginx/access.log /data/config/log/php/error.log /data/config/log/nextcloud.log; do
  # Make sure directory exists
  mkdir -p "$(dirname "$var")"
  # Clean files
  if [ -f "$var" ]; then rm -r "$var"; fi
  # Create symlink
  ln -sf /proc/1/fd/1 "$var"
done

# Add new log info to config.php
for var in /defaults/config.php /data/config/www/nextcloud/config/config.php; do
  sed -i "/logfile/d" "$var"
  sed -i "/log_type/d" "$var"
  sed -i "/log_rotate_size/d" "$var"  
  sed -i "2a\ \ 'logfile' => '/data/config/log/nextcloud.log'," "$var"
  sed -i "2a\ \ 'log_type' => 'file'," "$var"
  sed -i "2a\ \ 'log_rotate_size' => 0," "$var"
done
