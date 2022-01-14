#!/usr/bin/env bashio

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash."

##############
# LAUNCH APP #
##############

node ./dist/server.js
