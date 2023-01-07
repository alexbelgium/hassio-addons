#!/usr/bin/env bashio
# shellcheck shell=bash

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash."

##############
# LAUNCH APP #
##############

python -u /app/flaresolverr.py
