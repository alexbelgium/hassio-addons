#!/usr/bin/env bashio
# shellcheck shell=bash
set -e
# hadolint ignore=SC2155

bashio::log.info "Starting application"
sudo -u node -s /bin/sh -c "/home/node/signalk/startup.sh"
