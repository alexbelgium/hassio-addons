#!/usr/bin/env bashio

DB_NAME=$(echo $DB_NAME | tr -d '"')

if [ ! -f "/data/$DB_NAME.sqlite" ]; then
  mv "/var/www/webtrees/data/$DB_NAME.sqlite" /data || bashio::log.fatal "error : database /var/www/webtrees/data/$DB_NAME.sqlite not found"
  ln -s "/data/$DB_NAME.sqlite" /var/www/webtrees/data
  bashio:log.warning "No existing database found with the name selected, creating a new one"
fi

bashio::log.info "Starting apache, please wait then login with $WT_USER : $WT_PASS"

exec apache2-foreground
