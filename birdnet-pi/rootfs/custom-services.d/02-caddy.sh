#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Dependencies
sockfile="empty"
until [[ -e /var/run/dbus/system_bus_socket ]] && [[ -e "$sockfile" ]]; do
    sleep 1s
    sockfile="$(find /run/php -name *.sock)"
done

# Correct fpm.sock
chown caddy:caddy /run/php/php*-fpm.sock
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" /etc/caddy/Caddyfile

# Update caddyfile with password
/."$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh &>/dev/null || true

echo "Starting service: caddy"
/usr/bin/caddy run --config /etc/caddy/Caddyfile
