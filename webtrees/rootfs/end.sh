#!/usr/bin/env bashio

DB_NAME=$(echo $DB_NAME | tr -d '"')

if [ ! -f /data/config.ini.php ] && [ -f /var/www/webtrees/data/config.ini.php ]; then
mv /var/www/webtrees/data/config.ini.php /data
ln -s /data/config.ini.php /var/www/webtrees/data
else
bashio::log.fatal "error : config not found"
fi

if [ ! -f "/data/$DB_NAME.sqlite" ] && [ -f "/var/www/webtrees/data/$DB_NAME.sqlite" ]; then
mv "/var/www/webtrees/data/$DB_NAME.sqlite" /data
ln -s "/data/$DB_NAME.sqlite" /var/www/webtrees/data
else
bashio::log.fatal "error : database /var/www/webtrees/data/$DB_NAME.sqlite not found"
fi

bashio::log.info "Starting apache, please wait then login with $WT_USER : $WT_PASS"

exec apache2-foreground
