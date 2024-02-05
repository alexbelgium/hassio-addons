#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Export env #
##############

##################
# Starting redis #
##################
exec redis-server & bashio::log.info "Starting redis"

####################
# Starting mongodb #
####################
mkdir -p /data/db
exec mongod --bind_ip 127.0.0.1 & bashio::log.info "Starting mongod"

################
# Starting app #
################
bashio::log.info "Starting overleaf"
/./sbin/my_init

##################
# Starting nginx #
##################
#nginx
