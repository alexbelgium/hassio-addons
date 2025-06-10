#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Correct /config permissions after startup
chown pi:pi /config

# Waiting for dbus
until [[ -e /var/run/dbus/system_bus_socket ]]; do
  sleep 1s
done

TZ_VALUE="$(timedatectl show -p Timezone --value)"
export TZ="$TZ_VALUE"
echo "Starting service: php pfm"
exec /usr/sbin/php-fpm* -F
