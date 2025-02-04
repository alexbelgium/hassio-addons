#!/usr/bin/env bash
# shellcheck shell=bash
# Improved BirdNET-Pi Monitoring Script with Recovery Alerts and Condensed Logs

HOME="/home/pi"

########################################
# Logging Functions (color-coded for terminal clarity)
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
# Wait 5 minutes for system stabilization
########################################
sleep 5m

log_green "Starting service: throttlerecording"

########################################
# Define Directories, Files, and Constants
########################################
INGEST_DIR="${RECS_DIR/StreamData:-$HOME/BirdSongs/StreamData}"
INGEST_DIR=$(readlink -f "$INGEST_DIR")
if [ /tmp/StreamData ]; then
    INGEST_DIR="/tmp/StreamData"
fi
ANALYZING_NOW_FILE="$INGEST_DIR/analyzing_now.txt"
touch "$ANALYZING_NOW_FILE"

# Ensure directories and set permissions
mkdir -p "$INGEST_DIR" || { log_red "Failed to create directory: $INGEST_DIR"; exit 1; }
chown -R pi:pi "$INGEST_DIR" || log_yellow "Could not change ownership for $INGEST_DIR"
chmod -R 755 "$INGEST_DIR" || log_yellow "Could not set permissions for $INGEST_DIR"

# Services to monitor
SERVICES=(birdnet_analysis chart_viewer spectrogram_viewer icecast2 birdnet_recording birdnet_log birdnet_stats)

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
# Notification Functions
########################################

apprisealert() {
    local issue_message="$1"
    local current_time
    current_time=$(date +%s)
    local time_diff=$(( current_time - last_notification_time ))

    # Throttle notifications
    if (( time_diff < NOTIFICATION_INTERVAL )); then
        log_yellow "Notification suppressed (last sent ${time_diff} seconds ago)."
        return
    fi

    local stopped_service="<br><b>Stopped services:</b> "
    for service in "${SERVICES[@]}"; do
        if [[ "$(systemctl is-active "$service")" != "active" ]]; then
            stopped_service+="$service; "
        fi
    done

    local notification="<b>Issue:</b> $issue_message"
    notification+="$stopped_service"
    notification+="<br><b>System:</b> ${SITE_NAME:-$(hostname)}"
    notification+="<br>Available disk space: $(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $4}')"
    [[ -n "$BIRDNETPI_URL" ]] && notification+="<br><a href=\"$BIRDNETPI_URL\">Access your BirdNET-Pi</a>"

    local TITLE="BirdNET-Analyzer Alert"
    if [[ -f "$HOME/BirdNET-Pi/birdnet/bin/apprise" && -s "$HOME/BirdNET-Pi/apprise.txt" ]]; then
        "$HOME/BirdNET-Pi/birdnet/bin/apprise" -vv -t "$TITLE" -b "$notification" \
            --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
        last_notification_time=$current_time
        issue_reported=1
    else
        log_red "Apprise not configured or missing!"
    fi
}

apprisealert_recovery() {
    # Only send a recovery message if we had previously reported an issue
    if (( issue_reported == 1 )); then
        log_green "$(date) INFO: System is back to normal. Sending recovery notification."

        local TITLE="BirdNET-Pi System Recovered"
        local notification="<b>All monitored services are back to normal.</b><br>"
        notification+="<b>System:</b> ${SITE_NAME:-$(hostname)}<br>"
        notification+="Available disk space: $(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $4}')"

        if [[ -f "$HOME/BirdNET-Pi/birdnet/bin/apprise" && -s "$HOME/BirdNET-Pi/apprise.txt" ]]; then
            "$HOME/BirdNET-Pi/birdnet/bin/apprise" -vv -t "$TITLE" -b "$notification" \
                --input-format=html --config="$HOME/BirdNET-Pi/apprise.txt"
        fi
        issue_reported=0
    fi
}

########################################
# Helper Checks
########################################

check_disk_space() {
    local current_usage
    current_usage=$(df -h "$HOME/BirdSongs" | awk 'NR==2 {print $5}' | sed 's/%//')

    if (( current_usage >= DISK_USAGE_THRESHOLD )); then
        log_red "$(date) INFO: Disk usage is at ${current_usage}% (CRITICAL!)"
        apprisealert "Disk usage critical: ${current_usage}%"
        return 1
    else
        # Example: "Tue Feb 4 20:18:49 CET 2025 INFO: Disk usage is within acceptable limits (30%)."
        log_green "$(date) INFO: Disk usage is within acceptable limits (${current_usage}%)."
        return 0
    fi
}

check_analyzing_now() {
    local current_file
    current_file=$(cat "$ANALYZING_NOW_FILE" 2>/dev/null)
    if [[ "$current_file" == "$analyzing_now" ]]; then
        (( same_file_counter++ ))
    else
        same_file_counter=0
        analyzing_now="$current_file"
    fi

    if (( same_file_counter >= SAME_FILE_THRESHOLD )); then
        log_red "$(date) INFO: 'analyzing_now' file unchanged for $SAME_FILE_THRESHOLD iterations."
        apprisealert "No change in analyzing_now for ${SAME_FILE_THRESHOLD} iterations"
        "$HOME/BirdNET-Pi/scripts/restart_services.sh"
        same_file_counter=0
        return 1
    else
        # Only log if it changed this iteration
        if (( same_file_counter == 0 )); then
            log_green "$(date) INFO: 'analyzing_now' file has been updated."
        fi
        return 0
    fi
}

check_queue() {
    local wav_count
    wav_count=$(find -L "$INGEST_DIR" -maxdepth 1 -name '*.wav' | wc -l)

    # Example: "Tue Feb 4 20:18:50 CET 2025 INFO: Queue is at a manageable level (1 wav files)."
    log_info "$(date) INFO: Queue is at a manageable level (${wav_count} wav files)."

    # Below are your existing thresholds/logic. Adjust as needed:
    if (( wav_count > 50 )); then
        log_red "$(date) INFO: Queue >50. Stopping recorder + restarting analyzer."
        apprisealert "Queue exceeded 50: stopping recorder, restarting analyzer."
        sudo systemctl stop birdnet_recording
        sudo systemctl restart birdnet_analysis
        return 1
    elif (( wav_count > 30 )); then
        log_red "$(date) INFO: Queue >30. Restarting analyzer."
        apprisealert "Queue exceeded 30: restarting analyzer."
        sudo systemctl restart birdnet_analysis
        return 1
    fi
    return 0
}

check_services() {
    local inactive_services=()
    for service in "${SERVICES[@]}"; do
        if [[ "$(systemctl is-active "$service")" != "active" ]]; then
            inactive_services+=("$service")
        fi
    done

    if (( ${#inactive_services[@]} == 0 )); then
        # Example: "Tue Feb 4 20:18:50 CET 2025 INFO: All services are active"
        log_green "$(date) INFO: All services are active"
        return 0
    else
        log_red "$(date) INFO: Some services are NOT active: ${inactive_services[*]}"
        apprisealert "One or more services inactive: ${inactive_services[*]}"
        return 1
    fi
}

########################################
# Main Monitoring Loop
########################################

while true; do
    sleep 61
    log_info "----------------------------------------"
    log_info "$(date) INFO: Starting monitoring check"
    any_issue=0

    # 1) Disk usage
    check_disk_space || any_issue=1

    # 2) 'analyzing_now' file
    check_analyzing_now || any_issue=1

    # 3) Queue check
    check_queue || any_issue=1

    # 4) Services check
    check_services || any_issue=1

    # Final summary
    if (( any_issue == 0 )); then
        # Example: "Tue Feb 4 20:18:50 CET 2025 INFO: All systems are functioning normally"
        log_green "$(date) INFO: All systems are functioning normally"
        apprisealert_recovery
    else
        log_red "$(date) INFO: Issues detected. System status is not fully operational."
    fi
    log_info "----------------------------------------"
done
