#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

bashio::log.info "Starting ente..."
exec /usr/bin/museum &

bashio::log.info "Starting minio..."
exec /usr/local/bin/minio server /data --address ":3200" &

bashio::log.info "Starting ente-web..."
[ -n "$DISABLE_WEB_UI" ] || exec /usr/bin/ente-web
