#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155

####################
# Define variables #
####################

bashio::log.info "Defining variables"

if bashio::config.has_value "PUID"; then export USERMAP_UID=$(bashio::config "PUID"); fi
if bashio::config.has_value "PGID"; then export USERMAP_GID=$(bashio::config "PGID"); fi
if bashio::config.has_value "TZ"; then export PAPERLESS_TIME_ZONE=$(bashio::config "TZ"); fi
if bashio::config.has_value "OCRLANG"; then
    PAPERLESS_OCR_LANGUAGES="$(bashio::config "OCRLANG")"
    export PAPERLESS_OCR_LANGUAGES=${PAPERLESS_OCR_LANGUAGES,,}
fi
if bashio::config.has_value "PAPERLESS_OCR_MODE"; then export PAPERLESS_OCR_MODE=$(bashio::config "PAPERLESS_OCR_MODE"); fi

export PAPERLESS_ADMIN_PASSWORD="admin"
export PAPERLESS_ADMIN_USER="admin"

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

###############
# Staring app #
###############
bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."

/./sbin/docker-entrypoint.sh /usr/local/bin/paperless_cmd.sh
