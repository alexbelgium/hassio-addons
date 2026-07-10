#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Wait for PHP-FPM only. D-Bus is optional in standalone Docker mode and must
# not prevent the web service from starting.
sockfile=""
until [[ -n "$sockfile" ]] && [[ -e "$sockfile" ]]; do
    sleep 1s
    sockfile="$(find /run/php -name "*.sock" -print -quit 2> /dev/null || true)"
done

# Correct fpm.sock
chown caddy:caddy "$sockfile"
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" /helpers/caddy_ingress.sh
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" /etc/caddy/Caddyfile
sed -i "s|/run/php/php-fpm.sock|$sockfile|g" "$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh

# Set timezone without requiring D-Bus.
TZ_VALUE="${TZ:-}"
if [[ -S /var/run/dbus/system_bus_socket ]] && command -v timedatectl > /dev/null 2>&1; then
    TZ_VALUE="$(timedatectl show -p Timezone --value 2> /dev/null || true)"
fi
export TZ="${TZ_VALUE:-Etc/UTC}"

# Update caddyfile with password
"$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh &> /dev/null || true

echo "Starting service: caddy"
exec /usr/bin/caddy run --config /etc/caddy/Caddyfile
