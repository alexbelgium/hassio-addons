#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Correct /config permissions after startup
chown pi:pi /config

# D-Bus is not guaranteed to be available in standalone Docker mode. Use the
# configured TZ directly and only query timedatectl when its bus is ready.
TZ_VALUE="${TZ:-}"
if [[ -S /var/run/dbus/system_bus_socket ]] && command -v timedatectl > /dev/null 2>&1; then
    TZ_VALUE="$(timedatectl show -p Timezone --value 2> /dev/null || true)"
fi
export TZ="${TZ_VALUE:-Etc/UTC}"

echo "Starting service: php fpm"
exec /usr/sbin/php-fpm* -F
