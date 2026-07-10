#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Correct /config permissions after startup
chown pi:pi /config

# Ensure the PHP-FPM runtime directory exists. It is normally created by
# systemd-tmpfiles (/usr/lib/tmpfiles.d/php*-fpm.conf), which does not run in
# this container - so on a fresh/tmpfs /run the socket cannot be bound and the
# WebUI never starts. Create it here so the web stack works with or without
# Home Assistant Supervisor.
mkdir -p /run/php
chown www-data:www-data /run/php 2> /dev/null || true

# Set timezone without requiring Home Assistant Supervisor or D-Bus.
TZ_VALUE="${TZ:-}"
if [[ -S /var/run/dbus/system_bus_socket ]] && command -v timedatectl > /dev/null 2>&1; then
    TZ_VALUE="$(timedatectl show -p Timezone --value 2> /dev/null || true)"
fi
export TZ="${TZ_VALUE:-Etc/UTC}"

echo "Starting service: php pfm"
exec /usr/sbin/php-fpm* -F
