#!/bin/bash

# Copy data
cp -rnf /var/www/baikal/* /data/

# Start app
/./etc/init.d/php8.1-fpm start && \
chown -R nginx:nginx /var/www/baikal/Specific && \
nginx -g \"daemon off
