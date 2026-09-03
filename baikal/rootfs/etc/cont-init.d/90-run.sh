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

# Start app
# Find the PHP FPM service script and start it
find /etc/init.d -type f -name "php*-fpm" -exec {} start \; \
    && chown -R nginx:nginx /data/Specific \
    && nginx -g "daemon off;"
