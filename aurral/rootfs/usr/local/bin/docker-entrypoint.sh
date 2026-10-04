#!/bin/sh
set -e

# Use the download_folder option. The Dockerfile only sets a default
OPTIONS=/data/options.json
if [ -f "$OPTIONS" ]; then
    folder=$(node -e 'const o = require(process.argv[1]); process.stdout.write(o.download_folder || "")' "$OPTIONS")
    if [ -n "$folder" ]; then
        export DOWNLOAD_FOLDER="$folder"
    fi
fi

# Aurral reads WEEKLY_FLOW_FOLDER as a deprecated alias for DOWNLOAD_FOLDER that
# takes precedence over it, so it must not be set. Flows go to a subfolder of
# the download folder
unset WEEKLY_FLOW_FOLDER

mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER}"
exec "$@"
