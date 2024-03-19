#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "Creating folders"
mkdir -p /config/library

######################
# CONFIGURE POSTGRES #
######################

bashio::log.info "Setting postgres..."
if [[ "$DATABASE_URL" == *"localhost"* ]]; then
  echo "... with local database"
  echo "... set database in /config/postgres"
  mkdir -p /config/postgres
  mkdir -p /var/run/postgresql 
  chown postgres:postgres /var/run/postgresql
  chown -R postgres:postgres /config/postgres
  chmod 0700 /config/postgres
  
  echo "... starting server"
  service postgresql start & true
  sleep 5
  
  echo "... create user"
  # Create database if does not exist
  echo "CREATE ROLE postgres WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'homeassistant';
  \q"> setup_postgres.sql
  psql "postgres://postgres:homeassistant&localhost:5432/linkwarden" < setup_postgres.sql || true
  
  if [ -e /config/postgres/postgresql.conf ]; then
    echo "... database already configured"
  else
   echo "configure database"
    postgres /usr/lib/postgresql/*/bin/initdb
  fi
else
  echo "... using external database"
fi

########################
# CONFIGURE LINKWARDEN #
########################

bashio::log.info "Starting app..."
yarn prisma migrate deploy
yarn start docker-entrypoint.sh
