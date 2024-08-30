#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

###################################
# Export all addon options as env #
###################################

bashio::log.info "Setting variables"

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq ."$KEYS" "${JSONSOURCE}")
    line="${KEYS}='${VALUE//[\"\']/}'"
    # text
    if bashio::config.false "verbose" || [[ "${KEYS}" == *"PASS"* ]]; then
        bashio::log.blue "${KEYS}=******"
    else
        bashio::log.blue "$line"
    fi
    # Use locally
    export "${KEYS}=${VALUE//[\"\']/}"
done

######################
# Switch of database #
######################

if [ -f /share/postgresql_immich.tar.gz ]; then
    bashio::log.warning "Your previous database was exported to /share/postgresql_immich.tar.gz"
elif [ -d /data/postgresql ]; then
    bashio::log.warning "------------------------------------"
    bashio::log.warning "Internal postgres database detected, copying to /share/postgresql_immich.tar.gz"
    bashio::log.warning "------------------------------------"
    tar -zcvf /share/postgresql_immich.tar.gz /data/postgresql
    rm -r /data/postgresql
fi

###################
# Define database #
###################

bashio::log.info "Defining database"
bashio::log.info "-----------------"

bashio::log.info "Connecting to external postgresql"
bashio::log.info ""

# Check if values exist
if ! bashio::config.has_value 'DB_USERNAME' && \
    ! bashio::config.has_value 'DB_HOSTNAME' && \
    ! bashio::config.has_value 'DB_PASSWORD' && \
    ! bashio::config.has_value 'DB_DATABASE_NAME' && \
    ! bashio::config.has_value 'JWT_SECRET' && \
    ! bashio::config.has_value 'DB_PORT'; then
    bashio::exit.nok "Please make sure that the following options are set : DB_USERNAME, DB_HOSTNAME, DB_PASSWORD, DB_DATABASE_NAME, DB_PORT"
fi

# Settings parameters
export DB_USERNAME=$(bashio::config 'DB_USERNAME')
export DB_HOSTNAME=$(bashio::config 'DB_HOSTNAME')
export DB_PASSWORD=$(bashio::config 'DB_PASSWORD')
export DB_DATABASE_NAME=$(bashio::config 'DB_DATABASE_NAME')
export DB_PORT=$(bashio::config 'DB_PORT')
export JWT_SECRET=$(bashio::config 'JWT_SECRET')

# Export variables
if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "$DB_USERNAME" > /var/run/s6/container_environment/DB_USERNAME
    printf "%s" "$DB_PASSWORD" > /var/run/s6/container_environment/DB_PASSWORD
    printf "%s" "$DB_DATABASE_NAME" > /var/run/s6/container_environment/DB_DATABASE_NAME
    printf "%s" "$DB_PORT" > /var/run/s6/container_environment/DB_PORT
    printf "%s" "$DB_HOSTNAME" > /var/run/s6/container_environment/DB_HOSTNAME
    printf "%s" "$JWT_SECRET" > /var/run/s6/container_environment/JWT_SECRET
fi

{
    printf "%s\n" "DB_USERNAME=\"$DB_USERNAME\""
    printf "%s\n" "DB_PASSWORD=\"$DB_PASSWORD\""
    printf "%s\n" "DB_DATABASE_NAME=\"$DB_DATABASE_NAME\""
    printf "%s\n" "DB_PORT=\"$DB_PORT\""
    printf "%s\n" "DB_HOSTNAME=\"$DB_HOSTNAME\""
    printf "%s\n" "JWT_SECRET=\"$JWT_SECRET\""
} >> ~/.bashrc

###################
# Create database #
###################

# Create database if does not exist
echo "CREATE ROLE root WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'securepassword';
     CREATE DATABASE immich; CREATE USER immich WITH ENCRYPTED PASSWORD 'immich'; GRANT ALL PRIVILEGES ON DATABASE immich to immich;
\q"> setup_postgres.sql
psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT" < setup_postgres.sql || true

# Clean
rm setup_postgres.sql
