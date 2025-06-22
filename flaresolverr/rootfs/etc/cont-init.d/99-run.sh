#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

bashio::log.warning "Warning - minimum configuration recommended: 2 CPU cores and 4 GB of memory. Otherwise the system may become unresponsive or crash."

##############
# LAUNCH APP #
##############

exec /usr/bin/dumb-init -- python -u /app/flaresolverr.py
