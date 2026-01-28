#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

export PYTHONPATH=/app
export PULSE_SERVER=unix:/run/pulse/native

cd /app

bashio::log.info "Starting BirdNET-PiPy services"

python3 -m model_service.inference_server &
python3 -m core.api &
python3 -m core.main &

/usr/local/bin/start-icecast.sh &

bashio::net.wait_for 5002 localhost 300
bashio::log.info "BirdNET-PiPy API is available"

exec nginx
