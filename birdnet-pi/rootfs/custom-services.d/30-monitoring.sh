#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

echo "Starting service: throttlerecording"
touch "$HOME"/BirdSongs/StreamData/analyzing_now.txt

# variables for readability
srv="birdnet_recording"
analyzing_now="."
counter=10
set +u
# shellcheck disable=SC1091
source /config/birdnet.conf 2>/dev/null

# Ensure folder exists
ingest_dir="$RECS_DIR/StreamData"

# Check permissions
mkdir -p "$ingest_dir"
chown -R pi:pi "$ingest_dir"
chmod -R 755 "$ingest_dir"
ingest_dir="$(readlink -f "$ingest_dir")" || true
mkdir -p "$ingest_dir"
chown -R pi:pi "$ingest_dir"
chmod -R 755 "$ingest_dir"

while true; do
    sleep 61

    # Restart analysis if clogged
    ############################

    if (( counter <= 0 )); then
       latest="$(cat "$ingest_dir"/analyzing_now.txt)"
       if [[ "$latest" == "$analyzing_now" ]]; then
          echo "$(date) WARNING no change in analyzing_now for 10 iterations, restarting services"
          /."$HOME"/BirdNET-Pi/scripts/restart_services.sh
       fi
       counter=10
       analyzing_now=$(cat "$ingest_dir"/analyzing_now.txt)
    fi

    # Pause recorder to catch-up
    ############################

    wavs="$(find "$ingest_dir" -maxdepth 1 -name '*.wav' | wc -l)"
    state="$(systemctl is-active "$srv")"

    bashio::log.green "$(date)    INFO ${wavs} wav files waiting in $ingest_dir, $srv state is $state"

    if (( wavs > 100 )) && [[ "$state" == "active" ]]; then
        sudo systemctl stop "$srv"
        bashio::log.red "$(date) WARNING stopped $srv service"
    elif (( wavs <= 100 )) && [[ "$state" != "active" ]]; then
        sudo systemctl start $srv
        bashio::log.yellow "$(date)    INFO started $srv service"
    fi

    ((counter--))
done
