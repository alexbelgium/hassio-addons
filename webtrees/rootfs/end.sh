#!/usr/bin/env bashio

DB_NAME=$(echo $DB_NAME | tr -d '"')

bashio::log.info "Starting apache, using database $WEBTREES_HOME/$DB_NAME please wait then login with $WT_USER : $WT_PASS"

exec apache2-foreground
