#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Dependencies
sockfile="empty"
until [[ -e /var/run/dbus/system_bus_socket ]] && [[ -e "$sockfile" ]]; do
    sleep 1s
    sockfile="$(find /run/php -name "*.sock")"
done

# Correct fpm.sock
chown caddy:caddy /run/php/php*-fpm.sock
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" /helpers/caddy_ingress.sh
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" /etc/caddy/Caddyfile
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" "$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh

# Set timezone
TZ_VALUE="$(timedatectl show -p Timezone --value)"
export TZ="$TZ_VALUE"

# Update caddyfile with password
/."$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh &> /dev/null || true

echo "Starting service: caddy"
/usr/bin/caddy run --config /etc/caddy/Caddyfile
