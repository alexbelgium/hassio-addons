#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Set timezone
TZ_VALUE="$(timedatectl show -p Timezone --value)"
export TZ="$TZ_VALUE"

echo "Starting service: nginx"
nginx
