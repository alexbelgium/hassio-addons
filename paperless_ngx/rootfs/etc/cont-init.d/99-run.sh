#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Staring redis
exec redis-server & bashio::log.info "Starting redis"

# Avoid overcommit memory
bashio::log.info "Avoid overcommit memory"
sysctl vm.overcommit_memory=1

bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."
