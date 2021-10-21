#!/bin/bash

if [ ! -f /data/config.ini.php ] && [ -f /var/www/webtrees/data/config.ini.php ]; then
mv /var/www/webtrees/data/config.ini.php /data
ln -s /data/config.ini.php /var/www/webtrees/data
else
echo "error : config not found"
fi

if [ ! -f /data/$DB_NAME ] && [ -f /var/www/webtrees/data/$DB_NAME ]; then
mv /var/www/webtrees/data/$DB_NAME /data
ln -s /data/$DB_NAME /var/www/webtrees/data
else
echo "error : database not found"
fi

exec apache2-foreground
