#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

bashio::log.info "Starting services"

# Loop through each directory in /etc/services.d/
for dir in /etc/services.d/*; do
	# Check if the directory contains a 'run' file
	if [ -f "$dir/run" ]; then
		# Execute the 'run' file
		echo "Starting service in $dir"
		bash "$dir/run"
	else
		echo "No run file found in $dir"
	fi
done
