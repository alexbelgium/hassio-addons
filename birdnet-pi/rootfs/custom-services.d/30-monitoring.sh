#!/usr/bin/env bash
# shellcheck shell=bash
# Improved BirdNET-Pi Monitoring Script with Recovery Alerts and Condensed Logs

HOME="/home/pi"

########################################
# Logging Functions (color-coded for terminal clarity)
########################################
log_green() { echo -e "\033[32m$1\033[0m"; }
log_red() { echo -e "\033[31m$1\033[0m"; }
log_yellow() { echo -e "\033[33m$1\033[0m"; }
log_blue() { echo -e "\033[34m$1\033[0m"; }

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
INGEST_DIR="$(readlink -f "$HOME/BirdSongs/StreamData")"
ANALYZING_NOW_FILE="$INGEST_DIR/analyzing_now.txt"
touch "$ANALYZING_NOW_FILE"
BIRDSONGS_DIR="$(readlink -f "$HOME/BirdSongs/Extracted/By_Date")"

# Ensure directories and set permissions
mkdir -p "$INGEST_DIR" || {
    log_red "Failed to create directory: $INGEST_DIR"
    exit 1
}
chown -R pi:pi "$INGEST_DIR" || log_yellow "Could not change ownership for $INGEST_DIR"
chmod -R 755 "$INGEST_DIR" || log_yellow "Could not set permissions for $INGEST_DIR"

# Services to monitor
SERVICES=(birdnet_analysis chart_viewer spectrogram_viewer birdnet_recording birdnet_log birdnet_stats)

########################################
# Notification settings
########################################
NOTIFICATION_INTERVAL=1800 # 30 minutes in seconds
NOTIFICATION_INTERVAL_IN_MINUTES=$((NOTIFICATION_INTERVAL / 60))
last_notification_time=0
issue_reported=0 # 1 = an issue was reported, 0 = system is normal
declare -A SERVICE_INACTIVE_COUNT=()

# Disk usage threshold (percentage)
DISK_USAGE_THRESHOLD=95

# "Analyzing" file check variables
same_file_counter=0
SAME_FILE_THRESHOLD=2
if [[ -f "$ANALYZING_NOW_FILE" ]]; then
    analyzing_now=$(< "$ANALYZING_NOW_FILE")
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

    # Calculate time_diff in minutes since last notification
    local time_diff=$(((current_time - last_notification_time) / 60))

    # Throttle notifications
    if ((time_diff < NOTIFICATION_INTERVAL_IN_MINUTES)); then
        log_yellow "Notification suppressed (last sent ${time_diff} minutes ago)."
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
    notification+="<br>Available disk space: $(df -h "$BIRDSONGS_DIR" | awk 'NR==2 {print $4}')"
    notification+="<br>----Last log lines----"
    notification+="<br> $(timeout 15 cat /proc/1/fd/1 | head -n 5)"
    notification+="<br>----------------------"
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
    if ((issue_reported == 1)); then
        log_green "$(date) INFO: System is back to normal. Sending recovery notification."

        local TITLE="BirdNET-Pi System Recovered"
        local notification="<b>All monitored services are back to normal.</b><br>"
        notification+="<b>System:</b> ${SITE_NAME:-$(hostname)}<br>"
        notification+="Available disk space: $(df -h "$BIRDSONGS_DIR" | awk 'NR==2 {print $4}')"

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
    current_usage=$(df -h "$BIRDSONGS_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')

    if ((current_usage >= DISK_USAGE_THRESHOLD)); then
        log_red "$(date) INFO: Disk usage is at ${current_usage}% (CRITICAL!)"
        apprisealert "Disk usage critical: ${current_usage}%"
        return 1
    else
        log_green "$(date) INFO: Disk usage is within acceptable limits (${current_usage}%)."
        return 0
    fi
}

check_analyzing_now() {
    local current_file
    current_file=$(cat "$ANALYZING_NOW_FILE" 2> /dev/null)
    if [[ "$current_file" == "$analyzing_now" ]]; then
        ((same_file_counter++))
    else
        same_file_counter=0
        analyzing_now="$current_file"
    fi

    if ((same_file_counter >= SAME_FILE_THRESHOLD)); then
        log_red "$(date) INFO: 'analyzing_now' file unchanged for $SAME_FILE_THRESHOLD iterations."
        apprisealert "No change in analyzing_now for ${SAME_FILE_THRESHOLD} iterations"
        "$HOME/BirdNET-Pi/scripts/restart_services.sh"
        same_file_counter=0
        return 1
    else
        # Only log if it changed this iteration
        if ((same_file_counter == 0)); then
            log_green "$(date) INFO: 'analyzing_now' file has been updated."
        fi
        return 0
    fi
}

check_queue() {
    local wav_count
    wav_count=$(find -L "$INGEST_DIR" -maxdepth 1 -name '*.wav' | wc -l)

    log_green "$(date) INFO: Queue is at a manageable level (${wav_count} wav files)."

    if ((wav_count > 50)); then
        log_red "$(date) INFO: Queue >50. Stopping recorder + restarting analyzer."
        apprisealert "Queue exceeded 50: stopping recorder, restarting analyzer."
        sudo systemctl stop birdnet_recording
        sudo systemctl restart birdnet_analysis
        return 1
    elif ((wav_count > 30)); then
        log_red "$(date) INFO: Queue >30. Restarting analyzer."
        apprisealert "Queue exceeded 30: restarting analyzer."
        sudo systemctl restart birdnet_analysis
        return 1
    fi
    return 0
}

check_services() {
    local any_inactive=0

    for service in "${SERVICES[@]}"; do
        if [[ "$(systemctl is-active "$service")" != "active" ]]; then
            SERVICE_INACTIVE_COUNT["$service"]=$((SERVICE_INACTIVE_COUNT["$service"] + 1))

            if ((SERVICE_INACTIVE_COUNT["$service"] == 1)); then
                # First time inactive => Try to start
                log_yellow "$(date) INFO: Service '$service' is inactive. Attempting to start..."
                systemctl start "$service"
                any_inactive=1
            elif ((SERVICE_INACTIVE_COUNT["$service"] == 2)); then
                # Second consecutive time => Send an alert
                log_red "$(date) INFO: Service '$service' is still inactive after restart attempt."
                apprisealert "Service '$service' remains inactive after restart attempt."
                any_inactive=1
            else
                # Beyond second check => keep logging or do advanced actions
                log_red "$(date) INFO: Service '$service' inactive for ${SERVICE_INACTIVE_COUNT["$service"]} checks in a row."
                any_inactive=1
            fi
        else
            # Service is active => reset counter
            if ((SERVICE_INACTIVE_COUNT["$service"] > 0)); then
                log_green "$(date) INFO: Service '$service' is back to active. Resetting counter."
            fi
            SERVICE_INACTIVE_COUNT["$service"]=0
        fi
    done

    if ((any_inactive == 0)); then
        log_green "$(date) INFO: All services are active"
        return 0
    else
        log_red "$(date) INFO: One or more services are inactive"
        return 1
    fi
}

check_for_empty_stream() {
    local log_tail
    log_tail=$(timeout 15 cat /proc/1/fd/1 | tail -n 5)

    if echo "$log_tail" | grep -q "Haliastur indus"; then
        log_red "$(date) INFO: Potential empty stream detected (frequent 'Haliastur indus')."
        apprisealert "Potential empty stream detected — frequent 'Haliastur indus' in log"
        return 1
    fi
    return 0
}

########################################
# Main Monitoring Loop
########################################
TZ_VALUE="$(timedatectl show -p Timezone --value)"
export TZ="$TZ_VALUE"

while true; do
    sleep 61
    log_blue "----------------------------------------"
    log_blue "$(date) INFO: Starting monitoring check"
    any_issue=0

    # 1) Disk usage
    check_disk_space || any_issue=1

    # 2) 'analyzing_now' file
    check_analyzing_now || any_issue=1

    # 3) Queue check
    check_queue || any_issue=1

    # 4) Services check
    check_services || any_issue=1

    # 5) Check for potential empty stream
    check_for_empty_stream || any_issue=1

    # Final summary
    if ((any_issue == 0)); then
        log_green "$(date) INFO: All systems are functioning normally"
        apprisealert_recovery
    else
        log_red "$(date) INFO: Issues detected. System status is not fully operational."
    fi
    log_blue "----------------------------------------"
done
