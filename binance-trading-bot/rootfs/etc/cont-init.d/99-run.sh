#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Export env #
##############

##################
# Starting redis #
##################
exec redis-server &
bashio::log.info "Starting redis"

####################
# Starting mongodb #
####################
mkdir -p /data/db
exec mongod --bind_ip 127.0.0.1 &
bashio::log.info "Starting mongod"

################
# Starting app #
################
cd /srv || true
npm start docker-entrypoint.sh &
bashio::log.info "Starting binance bot"

#########################
# Starting Trading View #
#########################
python main.py &
bashio::log.info "Starting trading view"

##################
# Starting nginx #
##################
nginx
