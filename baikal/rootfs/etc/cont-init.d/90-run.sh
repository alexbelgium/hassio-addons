#!/bin/bash

# Copy data
cp -rnf /var/www/baikal/* /data/

# Fix permissions
chown -R nginx:nginx /data

# Start app
/./etc/init.d/php8.1-fpm start && \
    chown -R nginx:nginx /data/Specific && \
    nginx -g "daemon off;"
