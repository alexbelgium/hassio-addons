#!/usr/bin/env bashio
# shellcheck shell=bash

SITE_TITLE=$(bashio::config 'SITE_TITLE')
SERVER_DOMAIN=$(bashio::config 'SERVER_DOMAIN')
BASE_URL=$(bashio::config 'BASE_URL')

echo "site tile $SITE_TITLE"
echo "server domain $SERVER_DOMAIN"
echo "base url $BASE_URL"

# sed "s/^APP.*/APP      = $SITE_TITLE/" /data/gitea/conf/app.ini
# sed "s/^DOMAIN.*/DOMAIN      = $SERVER_DOMAIN/" /data/gitea/conf/app.ini
# sed "s/^ROOT_URL.*/ROOT_URL       = $BASE_URL/" /data/gitea/conf/app.ini

exec "$@"
