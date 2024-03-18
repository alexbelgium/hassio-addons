#!/command/with-contenv bashio
# shellcheck shell=bash
set -e
  
bashio::log.info "Creating folders"
mkdir -p /config/library
mkdir -p /config/database
touch /config/database/linkwarden.sqlite

bashio::log.info "Applying migrations"
rm -r /data_linkwarden/prisma/migrations
cd /data_linkwarden
npx prisma db push
npx prisma generate

bashio::log.info "Starting app..."
yarn prisma migrate deploy
yarn start docker-entrypoint.sh & true

bashio::log.info "Starting postgres..."
mkdir -p /config/postgres
mkdir -p /var/run/postgresql 
chown postgres:postgres /var/run/postgresql
chown -R postgres:postgres /config/postgres
chmod 0700 /config/postgres
if [ -e /config/postgres/postgresql.conf ]; then
  echo "Database already configured"
else
  postgres /usr/lib/postgresql/*/bin/initdb
fi
postgres /usr/lib/postgresql/*/bin/postgres -D /config/postgres/
