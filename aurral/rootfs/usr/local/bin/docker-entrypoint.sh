#!/bin/sh
set -e

# Use the download_folder option. The Dockerfile only sets a default
OPTIONS=/data/options.json
if [ -f "$OPTIONS" ]; then
    folder=$(node -e 'const o = require(process.argv[1]); process.stdout.write(o.download_folder || "")' "$OPTIONS")
    if [ -n "$folder" ]; then
        export LIBRARY_FOLDER="$folder"
    fi
fi

# The add-on keeps its data in /config/data (AURRAL_DATA_DIR). Installs that
# first started on the 3.0.1 add-on have their database in /config instead.
# Keep using it there rather than starting with an empty database
if [ -f /config/aurral.db ]; then
    if [ -f "${AURRAL_DATA_DIR}/aurral.db" ]; then
        echo "[warn] Found databases in both ${AURRAL_DATA_DIR} and /config. Using ${AURRAL_DATA_DIR}. Remove /config/aurral.db if you do not need it"
    else
        echo "[info] Using the database in /config"
        export AURRAL_DATA_DIR=/config
    fi
fi

mkdir -p "${AURRAL_DATA_DIR}"
mkdir -p "${LIBRARY_FOLDER}"
exec "$@"
