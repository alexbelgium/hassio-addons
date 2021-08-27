#!/bin/bash

echo "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash." 

##############
# LAUNCH APP #
##############

export APP_BASE_URL=$(jq --raw-output ".APP_BASE_URL" "/data/config.json")
echo 'Starting Joplin'
npm --prefix packages/server start
