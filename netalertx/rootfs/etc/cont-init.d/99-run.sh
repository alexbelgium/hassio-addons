#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting upstream app"
gosu netalertx /entrypoint.sh
