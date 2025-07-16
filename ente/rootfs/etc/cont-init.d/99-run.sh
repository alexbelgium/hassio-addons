#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

mkdir -p /config/ente/custom-logs
mkdir -p /config/data
mkdir -p /config/minio-data
mkdir -p /config/postgres-data
mkdir -p /config/scripts/compose

################
# Run services #
################

bashio::log.info "Starting services"
for dir in /etc/services.d/*; do
	# Check if the directory contains a 'run' file
	if [ -f "$dir/run" ]; then
		# Execute the 'run' file
		bashio::log.info "Starting service $dir"
		/."$dir/run"
	else
		bashio::log.fatal "No run file found in $dir"
	fi
done
