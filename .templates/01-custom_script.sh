#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug="${HOSTNAME#*-}"
bashio::log.info "Execute if existing custom script /config/${slug}.sh"

if [ -f /config/${slug}.sh ]; then
  chmod +x /config/"${slug}".sh
  /./config/"${slug}".sh
else
  bashio::log.info "... no script found"
fi

