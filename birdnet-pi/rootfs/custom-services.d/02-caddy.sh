#!/usr/bin/with-contenv bash
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

# update_caddyfile.sh rewrites the Caddyfile from scratch. 91-nginx_ingress.sh
# hooks the ingress site back into it, but if that hook ever fails to apply,
# caddy would start without a :8082 listener and ingress would answer 502.
# 91-nginx_ingress.sh writes /ingress_url when ingress is on and removes it when
# it is off, so this is a no-op in standalone mode.
if [[ -f /ingress_url ]] && ! grep -qE '^[[:space:]]*:8082[[:space:]]*\{' /etc/caddy/Caddyfile; then
    echo "Ingress site missing from the Caddyfile, re-adding it"
    /helpers/caddy_ingress.sh
fi

echo "Starting service: caddy"
exec /usr/bin/caddy run --config /etc/caddy/Caddyfile
