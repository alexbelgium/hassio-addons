#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

bashio::log.warning "App starting."

##############
# LAUNCH APP #
##############

chmod +x /app/dockerfiles/start.sh
/app/dockerfiles/start.sh
