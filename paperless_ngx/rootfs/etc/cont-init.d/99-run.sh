#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."

/./sbin/docker-entrypoint.sh
