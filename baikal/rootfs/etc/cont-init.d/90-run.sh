#!/bin/bash

# Copy data
cp -rnf /var/www/baikal/* /data/

# Fix permissions
chown -R nginx:nginx /data

# Start app
# Find the PHP FPM service script and start it
find /etc/init.d -type f -name "php*-fpm" -exec {} start \; \
                                                            && chown -R nginx:nginx /data/Specific \
                                    && nginx -g "daemon off;"
