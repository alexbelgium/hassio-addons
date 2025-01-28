#!/usr/bin/env bash
# shellcheck shell=bash
# Adapted from https://github.com/mcguirepr89/BirdNET-Pi/issues/393#issuecomment-1166445710

HOME="/home/pi"

# Define logging functions
log_green() { echo -e "\033[32m$1\033[0m"; }
log_red() { echo -e "\033[31m$1\033[0m"; }
log_yellow() { echo -e "\033[33m$1\033[0m"; }
log_info() { echo -e "\033[34m$1\033[0m"; }

# Read configuration
set +u
# shellcheck disable=SC1091
source /etc/birdnet/birdnet.conf

log_green "Starting service: throttlerecording"
touch "$HOME/BirdSongs/StreamData/analyzing_now.txt"

# Set constants
srv="birdnet_recording"
srv2="birdnet_analysis"
ingest_dir="$RECS_DIR/StreamData"
counter=10

# Ensure directories and permissions
mkdir -p "$ingest_dir"
chown -R pi:pi "$ingest_dir"
chmod -R 755 "$ingest_dir"

# Function to send notifications using Apprise
apprisealert() {
    local issue_message="$1"
    local notification=""
    local stopped_service="<br><b>Stopped services:</b> "

    # Check for stopped services
    services=(birdnet_analysis chart_viewer spectrogram_viewer icecast2 birdnet_recording birdnet_log birdnet_stats)
    for service in "${services[@]}"; do
        if [[ "$(systemctl is-active "$service")" == "inactive" ]]; then
            stopped_service+="$service; "
        fi
    done

    # Build notification message
    notification+="<b>Issue:</b> $issue_message"
    notification+="$stopped_service"
    notification+="<br><b>Additional information:</b>"
    notification+="<br><b>Since:</b> ${LASTCHECK:-unknown}"
    notification+="<br><b>System:</b> ${SITE_NAME:-$(hostname)}"
    notification+="<br>Available disk space: $(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $4}')"
    [[ -n "$BIRDNETPI_URL" ]] && notification+="<br><a href=\"$BIRDNETPI_URL\">Access your BirdNET-Pi</a>"

    # Send notification
    TITLE="BirdNET-Analyzer Alert"
    if [[ -f "$HOME/BirdNET-Pi/birdnet/bin/apprise" && -s "$HOME/BirdNET-Pi/apprise.txt" ]]; then
        "$HOME/BirdNET-Pi/birdnet/bin/apprise" -vv -t "$TITLE" -b "$notification" --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
    else
        log_red "Apprise not configured or missing!"
    fi
}

# Main loop
while true; do
    sleep 61

    # Restart analysis if clogged
    if ((counter <= 0)); then
        current_file="$(cat "$ingest_dir/analyzing_now.txt")"
        if [[ "$current_file" == "$analyzing_now" ]]; then
            log_yellow "$(date) WARNING: No change in analyzing_now for 10 iterations, restarting services"
            apprisealert "No change in analyzing_now for 10 iterations"
            "$HOME/BirdNET-Pi/scripts/restart_services.sh"
        fi
        counter=10
        analyzing_now="$current_file"
    fi

    # Check recorder state and queue length
    wav_count=$(find -L "$ingest_dir" -maxdepth 1 -name '*.wav' | wc -l)
    service_state=$(systemctl is-active "$srv")
    analysis_state=$(systemctl is-active "$srv2")

    log_green "$(date) INFO: $wav_count wav files waiting in $ingest_dir, $srv state is $service_state, $srv2 state is $analysis_state"

    # Pause recorder if queue is too large
    if ((wav_count > 50)); then
        log_red "$(date) WARNING: Too many files in queue, pausing $srv and restarting $srv2"
        apprisealert "Too many files in queue (>50)"
        sudo systemctl stop "$srv"
        sudo systemctl restart "$srv2"
        sleep 60
    elif ((wav_count > 30)); then
        log_red "$(date) WARNING: Too many files in queue, restarting $srv2"
        apprisealert "Queue growing large (>30)"
        sudo systemctl restart "$srv2"
        sleep 30
    fi

    # Check service states
    for service in "$srv" "$srv2"; do
        state="$(systemctl is-active "$service")"
        if [[ "$state" != "active" ]]; then
            log_yellow "$(date) INFO: Restarting $service service"
            apprisealert "$service is not active, restarting"
            sudo systemctl restart "$service"
        fi
    done

    ((counter--))
done
