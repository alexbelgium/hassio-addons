#!/bin/sh
set -e

# HA Supervisor injects addon options as env vars automatically.
# DOWNLOAD_FOLDER and WEEKLY_FLOW_FOLDER are set by HA from options.json,
# with the Dockerfile ENV values as fallbacks.

mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER:-/share/aurral/downloads}"
mkdir -p "${WEEKLY_FLOW_FOLDER:-/share/aurral/downloads/weekly-flow}"

exec "$@"
