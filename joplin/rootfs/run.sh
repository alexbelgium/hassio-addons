#!/usr/bin/env bash

echo "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash." 

##############
# LAUNCH APP #
##############

# Configure app
export APP_BASE_URL=$(bashio::config 'APP_BASE_URL')
bashio::log.info 'Starting Joplin'
npm --prefix packages/server start
