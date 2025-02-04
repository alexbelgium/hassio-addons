#!/usr/bin/env bash
# shellcheck shell=bash
# Improved BirdNET-Pi Monitoring Script with Recovery Alerts

HOME="/home/pi"

########################################
# Logging Functions
########################################
log_green()   { echo -e "\033[32m$1\033[0m"; }
log_red()     { echo -e "\033[31m$1\033[0m"; }
log_yellow()  { echo -e "\033[33m$1\033[0m"; }
log_info()    { echo -e "\033[34m$1\033[0m"; }

########################################
# Read configuration
########################################
set +u
# shellcheck disable=SC1091
source /etc/birdnet/birdnet.conf

########################################
# Wait 5 minute for system stabilization
########################################
sleep 5m

log_green "Starting service: throttlerecording"

########################################
# Define Directories, Files, and Constants
########################################
INGEST_DIR="${RECS_DIR/StreamData:-$HOME/BirdSongs/StreamData}"
ANALYZING_NOW_FILE="$INGEST_DIR/analyzing_now.txt"
touch "$ANALYZING_NOW_FILE"

# Ensure directories and set permissions
mkdir -p "$INGEST_DIR" || { log_red "Failed to create directory: $INGEST_DIR"; exit 1; }
chown -R pi:pi "$INGEST_DIR" || log_yellow "Could not change ownership for $INGEST_DIR"
chmod -R 755 "$INGEST_DIR" || log_yellow "Could not set permissions for $INGEST_DIR"

# Service names
RECORDER_SERVICE="birdnet_recording"
ANALYZER_SERVICE="birdnet_analysis"

# Notification settings
NOTIFICATION_INTERVAL=1800  # seconds (30 minutes)
last_notification_time=0
issue_reported=0  # 1 = an issue was reported, 0 = system is normal

# Disk usage threshold (percentage)
DISK_USAGE_THRESHOLD=95

# "Analyzing" file check variables
same_file_counter=0
SAME_FILE_THRESHOLD=10  
if [[ -f "$ANALYZING_NOW_FILE" ]]; then
    analyzing_now=$(<"$ANALYZING_NOW_FILE")
else
    analyzing_now=""
fi

########################################
# Functions
########################################

# Send an issue notification
apprisealert() {
    local issue_message="$1"
    local current_time
    current_time=$(date +%s)
    local time_diff=$(( current_time - last_notification_time ))

    if (( time_diff < NOTIFICATION_INTERVAL )); then
        log_yellow "Notification suppressed (last sent ${time_diff} seconds ago)"
        return
    fi

    local notification=""
    local stopped_service="<br><b>Stopped services:</b> "

    # Check for stopped services
    local services=(birdnet_analysis chart_viewer spectrogram_viewer icecast2 birdnet_recording birdnet_log birdnet_stats)
    for service in "${services[@]}"; do
        if [[ "$(systemctl is-active "$service")" != "active" ]]; then
            stopped_service+="$service; "
        fi
    done

    notification+="<b>Issue:</b> $issue_message"
    notification+="$stopped_service"
    notification+="<br><b>System:</b> ${SITE_NAME:-$(hostname)}"
    notification+="<br>Available disk space: $(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $4}')"
    [[ -n "$BIRDNETPI_URL" ]] && notification+="<br><a href=\"$BIRDNETPI_URL\">Access your BirdNET-Pi</a>"

    local TITLE="BirdNET-Analyzer Alert"
    if [[ -f "$HOME/BirdNET-Pi/birdnet/bin/apprise" && -s "$HOME/BirdNET-Pi/apprise.txt" ]]; then
        "$HOME/BirdNET-Pi/birdnet/bin/apprise" -vv -t "$TITLE" -b "$notification" --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
        last_notification_time=$current_time
        issue_reported=1  # Mark that an issue was reported
    else
        log_red "Apprise not configured or missing!"
    fi
}

# Send a "System is back to normal" notification
apprisealert_recovery() {
    # Only send a recovery message if we had previously reported an issue
    if (( issue_reported == 1 )); then
        log_green "$(date) INFO: System is back to normal. Sending recovery notification."

        local TITLE="BirdNET-Pi System Recovered"
        local notification="<b>All monitored services are back to normal.</b><br>"
        notification+="<b>System:</b> ${SITE_NAME:-$(hostname)}<br>"
        notification+="Available disk space: $(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $4}')"

        if [[ -f "$HOME/BirdNET-Pi/birdnet/bin/apprise" && -s "$HOME/BirdNET-Pi/apprise.txt" ]]; then
            "$HOME/BirdNET-Pi/birdnet/bin/apprise" -vv -t "$TITLE" -b "$notification" --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
        fi
        issue_reported=0  # Reset issue tracker
    fi
}

# Restart a service if inactive
check_and_restart_service() {
    local service_name="$1"
    local state
    state=$(systemctl is-active "$service_name")
    
    if [[ "$state" != "active" ]]; then
        log_yellow "$(date) INFO: Restarting $service_name"
        sudo systemctl restart "$service_name"
        sleep 61
        state=$(systemctl is-active "$service_name")

        if [[ "$state" != "active" ]]; then
            log_red "$(date) WARNING: $service_name could not restart"
            apprisealert "$service_name cannot restart! Your system seems stuck."
        fi
    fi
}

# Check disk usage
check_disk_space() {
    local current_usage
    current_usage=$(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if (( current_usage >= DISK_USAGE_THRESHOLD )); then
        log_red "$(date) WARNING: Disk usage is at ${current_usage}%"
        apprisealert "Disk usage critical: ${current_usage}%"
        return 1  # Indicate there is an issue
    fi
    return 0  # No disk issue
}

# Handle queue size
handle_queue() {
    local wav_count="$1"
    
    if (( wav_count > 50 )); then
        log_red "$(date) WARNING: Queue >50. Pausing ${RECORDER_SERVICE} and restarting ${ANALYZER_SERVICE}"
        apprisealert "Queue >50: ${RECORDER_SERVICE} paused, ${ANALYZER_SERVICE} restarted"
        sudo systemctl stop "$RECORDER_SERVICE"
        sudo systemctl restart "$ANALYZER_SERVICE"
        return 1
    elif (( wav_count > 30 )); then
        log_red "$(date) WARNING: Queue >30. Restarting ${ANALYZER_SERVICE}"
        apprisealert "Queue >30: ${ANALYZER_SERVICE} restarted"
        sudo systemctl restart "$ANALYZER_SERVICE"
        return 1
    else
        # Check if services are alive; attempt restarts if needed
        check_and_restart_service "$RECORDER_SERVICE"
        check_and_restart_service "$ANALYZER_SERVICE"
    fi

    return 0
}

########################################
# Main Monitoring Loop
########################################
while true; do
    sleep 61

    # Track whether any issue is found this iteration
    any_issue=0

    # 1) Check disk space
    if ! check_disk_space; then
        any_issue=1
    fi

    # 2) Check if analyzing_now file is stuck
    current_file=$(cat "$ANALYZING_NOW_FILE" 2>/dev/null)
    if [[ "$current_file" == "$analyzing_now" ]]; then
        (( same_file_counter++ ))
    else
        same_file_counter=0
        analyzing_now="$current_file"
    fi

    if (( same_file_counter >= SAME_FILE_THRESHOLD )); then
        log_yellow "$(date) WARNING: 'analyzing_now' unchanged for ${SAME_FILE_THRESHOLD} iterations"
        apprisealert "No change in analyzing_now for ${SAME_FILE_THRESHOLD} iterations"
        "$HOME/BirdNET-Pi/scripts/restart_services.sh"
        same_file_counter=0
        any_issue=1
    fi

    # 3) Queue check
    wav_count=$(find -L "$INGEST_DIR" -maxdepth 1 -name '*.wav' | wc -l)
    log_green "$(date) INFO: ${wav_count} wav files waiting in ${INGEST_DIR}"
    if ! handle_queue "$wav_count"; then
        any_issue=1
    fi

    # 4) Check all essential services are running
    services=(birdnet_analysis chart_viewer spectrogram_viewer icecast2 birdnet_recording birdnet_log birdnet_stats)
    for service in "${services[@]}"; do
        # If a service is inactive, we attempt to restart it in check_and_restart_service
        # but we also want to mark that there's an issue so we don't send a false 'recovery' message
        if [[ "$(systemctl is-active "$service")" != "active" ]]; then
            any_issue=1
            break
        fi
    done

    # If no issues are active but we had reported an issue previously,
    # send a single "System Recovered" message.
    if (( any_issue == 0 )); then
        apprisealert_recovery
    fi
done
