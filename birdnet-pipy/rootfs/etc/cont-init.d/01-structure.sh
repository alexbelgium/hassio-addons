#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

DATA_ROOT="/config/birdnet-pipy"
DATA_DIR="${DATA_ROOT}/data"

mkdir -p "${DATA_DIR}"

if [ -e /app/data ] && [ ! -L /app/data ]; then
    rm -rf /app/data
fi

if [ ! -L /app/data ]; then
    ln -s "${DATA_DIR}" /app/data
fi

mkdir -p \
    /app/data/config \
    /app/data/db \
    /app/data/audio/recordings \
    /app/data/audio/extracted_songs \
    /app/data/spectrograms \
    /app/data/flags
