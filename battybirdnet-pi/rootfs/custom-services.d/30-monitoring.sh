#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

sleep infinity

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

function apprisealert() {
    # Set failed check so it only runs once
    touch "$HOME"/BirdNET-Pi/failed_servicescheck
    NOTIFICATION=""
    STOPPEDSERVICE="<br><b>Stopped services:</b> "
    services=(birdnet_analysis
        chart_viewer
        spectrogram_viewer
        icecast2
        birdnet_recording
        birdnet_log
        birdnet_stats)
    for i in "${services[@]}"; do
        if [[ "$(sudo systemctl is-active "${i}".service)" == "inactive" ]]; then
            STOPPEDSERVICE+="${i}; "
        fi
    done
    NOTIFICATION+="$STOPPEDSERVICE"
    NOTIFICATION+="<br><b>Additional informations</b>: "
    NOTIFICATION+="<br><b>Since:</b> ${LASTCHECK:-unknown}"
    NOTIFICATION+="<br><b>System:</b> ${SITE_NAME:-$(hostname)}"
    NOTIFICATION+="<br>Available disk space: $(df -h "$(readlink -f "$HOME/BirdSongs")" | awk 'NR==2 {print $4}')"
    if [ -n "$BIRDNETPI_URL" ]; then
        NOTIFICATION+="<br> <a href=\"$BIRDNETPI_URL\">Access your BirdNET-Pi</a>"
    fi
    TITLE="BirdNET-Analyzer stopped"
    "$HOME"/BirdNET-Pi/birdnet/bin/apprise -vv -t "$TITLE" -b "${NOTIFICATION}" --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
}

while true; do
    sleep 61

    # Restart analysis if clogged
    ############################

    if ((counter <= 0)); then
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

    if ((wavs > 100)); then
        bashio::log.red "$(date) WARNING too many files in queue, pausing $srv"
        sudo systemctl stop "$srv"
        sudo systemctl restart birdnet_analysis
        if [ -s "$HOME/BirdNET-Pi/apprise.txt" ]; then apprisealert; fi
    elif [[ "$state" != "active" ]]; then
        bashio::log.yellow "$(date)    INFO started $srv service"
        sudo systemctl start $srv
        sudo systemctl restart birdnet_analysis
    fi

    ((counter--))
done
