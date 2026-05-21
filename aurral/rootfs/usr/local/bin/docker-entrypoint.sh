#!/bin/sh
set -e

mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER}"
mkdir -p "${WEEKLY_FLOW_FOLDER}"

exec "$@"
