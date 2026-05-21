#!/bin/sh
set -e

# Create the real directories in HA persistent storage that the symlinks point to
mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER:-/share/aurral/downloads}"
mkdir -p "${WEEKLY_FLOW_FOLDER:-/share/aurral/downloads/weekly-flow}"

exec "$@"
