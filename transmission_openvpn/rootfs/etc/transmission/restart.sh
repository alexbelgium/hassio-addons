#!/usr/bin/env bashio

bashio::log.fatal 'Tunnel down, addon restarting in 15 seconds'
sleep 15
bashio::addon.restart
