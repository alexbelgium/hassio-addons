#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

bashio::log.info "Defining variables"

if bashio::config.has_value "PUID"; then export USERMAP_UID=$(bashio::config "PUID"); fi
if bashio::config.has_value "PGID"; then export USERMAP_GID=$(bashio::config "PGID"); fi
if bashio::config.has_value "TZ"; then export PAPERLESS_TIME_ZONE=$(bashio::config "TZ"); fi
if bashio::config.has_value "OCRLANG"; then export PAPERLESS_OCR_LANGUAGES=$(bashio::config "OCRLANG"); fi
if bashio::config.has_value "PAPERLESS_OCR_MODE"; then export PAPERLESS_OCR_MODE=$(bashio::config "PAPERLESS_OCR_MODE"); fi

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."

/./sbin/docker-entrypoint.sh /usr/local/bin/paperless_cmd.sh
