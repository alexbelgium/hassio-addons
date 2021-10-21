#!/bin/bash

if [ -f /data/config.ini.php ]; then
mv /var/www/webtrees/data/config.ini.php /data
ln -s /data/config.ini.php /var/www/webtrees/data
fi

if [ -f /data/webtrees.sqlite ]; then
mv /var/www/webtrees/data/webtrees.sqlite /data
ln -s /data/webtrees.sqlite /var/www/webtrees/data
fi

exec apache2-foreground
