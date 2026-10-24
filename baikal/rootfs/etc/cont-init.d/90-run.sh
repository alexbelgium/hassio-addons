#!/bin/bash
set -e

# Baikal keeps its database in Specific and its configuration in config. The
# release ships both as empty folders, so they are created here rather than
# copied, and are then left alone : they hold the user's data
mkdir -p /data/config /data/Specific/db

# Everything else is application code, and is replaced on every start so that a
# rebuilt image actually replaces the code that is served
for item in /var/www/baikal/*; do
    name="$(basename "$item")"
    case "$name" in
        Specific | config) continue ;;
    esac
    rm -rf "/data/$name"
    cp -rf "$item" /data/
done

# Fix permissions
chown -R nginx:nginx /data

# After a version update Baikal redirects every request to its upgrade wizard
# until the database is upgraded, and DAV clients loop on that redirect (#3148).
# Run the wizard once nginx answers, as confirming it in the web admin would
configured="$(sed -n "s/^ *configured_version: *['\"]\?\([^'\"]*\).*/\1/p" /data/config/baikal.yaml 2>/dev/null || true)"
shipped="$(sed -n 's/^define("BAIKAL_VERSION", "\(.*\)");/\1/p' /data/Core/Distrib.php)"
if [ -n "$configured" ] && [ "$configured" != "$shipped" ]; then
    echo "Upgrading the Baikal database from $configured to $shipped"
    (
        until curl -s -o /dev/null http://127.0.0.1/; do sleep 1; done
        if curl -s "http://127.0.0.1/admin/install/?upgradeConfirmed=1" | grep -q "successfully upgraded"; then
            echo "Baikal database upgraded to $shipped"
        else
            echo "Baikal upgrade failed : open the web admin to see the error"
        fi
    ) &
fi

# Start app
# Find the PHP FPM service script and start it
find /etc/init.d -type f -name "php*-fpm" -exec {} start \; \
    && chown -R nginx:nginx /data/Specific \
    && nginx -g "daemon off;"
