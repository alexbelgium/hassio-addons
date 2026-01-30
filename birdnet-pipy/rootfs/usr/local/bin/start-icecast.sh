#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

# Start Icecast streaming server with FFmpeg audio capture from PulseAudio or RTSP

# Recording mode constants
# Source of truth: backend/config/constants.py
# Keep in sync when adding/removing modes
VALID_RECORDING_MODES=("pulseaudio" "http_stream" "rtsp")
DEFAULT_RECORDING_MODE="pulseaudio"

# Validate recording mode
is_valid_recording_mode() {
    local mode="$1"
    for valid_mode in "${VALID_RECORDING_MODES[@]}"; do
        [[ "$mode" == "$valid_mode" ]] && return 0
    done
    return 1
}

# Configuration from environment
STREAM_BITRATE="${STREAM_BITRATE:-320k}"
ICECAST_PASSWORD="${ICECAST_PASSWORD:-}"

# Validate Icecast password - reject insecure defaults
if [ -z "$ICECAST_PASSWORD" ] || [ "$ICECAST_PASSWORD" = "hackme" ]; then
    # Generate a random password if not set or using insecure default
    ICECAST_PASSWORD="$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)"
    echo "WARNING: ICECAST_PASSWORD not set or using insecure default."
    echo "         Generated random password for this session."
    echo "         Set ICECAST_PASSWORD in your environment for a persistent password."
fi

# Generate icecast config with secure password (template is mounted read-only)
ICECAST_CONFIG="/tmp/icecast.xml"
cat > "$ICECAST_CONFIG" << EOF
<icecast>
    <location>RPi Audio Stream</location>
    <admin>admin@localhost</admin>

    <limits>
        <clients>100</clients>
        <sources>2</sources>
        <workers>1</workers>
    </limits>

    <authentication>
        <source-password>${ICECAST_PASSWORD}</source-password>
        <relay-password>${ICECAST_PASSWORD}</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>${ICECAST_PASSWORD}</admin-password>
    </authentication>

    <hostname>localhost</hostname>

    <listen-socket>
        <port>8888</port>
    </listen-socket>

    <fileserve>1</fileserve>

    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel>
        <logsize>10000</logsize>
    </logging>

    <security>
        <chroot>0</chroot>
    </security>
</icecast>
EOF

# Read RTSP URL from user settings if recording mode is 'rtsp'
SETTINGS_FILE="/app/data/config/user_settings.json"
RTSP_STREAM_URL=""
if [ -f "$SETTINGS_FILE" ]; then
    RECORDING_MODE="$(jq -r '.audio.recording_mode // "'"$DEFAULT_RECORDING_MODE"'"' "$SETTINGS_FILE")"
    if ! is_valid_recording_mode "$RECORDING_MODE"; then
        echo "Warning: Unknown recording mode '$RECORDING_MODE', using default"
        RECORDING_MODE="$DEFAULT_RECORDING_MODE"
    fi
    if [ "$RECORDING_MODE" = "rtsp" ]; then
        RTSP_STREAM_URL="$(jq -r '.audio.rtsp_url // empty' "$SETTINGS_FILE")"
    fi
fi

echo "Starting Icecast streaming service..."
echo "  Stream bitrate: $STREAM_BITRATE"

# Determine audio source based on RTSP_STREAM_URL
# Use arrays to avoid eval and prevent command injection
if [ -n "$RTSP_STREAM_URL" ]; then
    echo "  Audio source: RTSP stream"
    # Hide credentials in log output
    RTSP_DISPLAY_URL="$(echo "$RTSP_STREAM_URL" | sed 's/:[^:@]*@/:***@/')"
    echo "  RTSP URL: $RTSP_DISPLAY_URL"
    AUDIO_ARGS=(-rtsp_transport tcp -timeout 10000000 -i "$RTSP_STREAM_URL")
else
    echo "  Audio source: PulseAudio (default)"

    # Wait for PulseAudio to be available
    echo "Waiting for PulseAudio..."
    MAX_RETRIES=30
    RETRY_COUNT=0
    while ! timeout 1 bash -c "echo > /dev/tcp/localhost/0" 2>/dev/null; do
        # Check if PulseAudio socket exists
        if [ -S "/run/pulse/native" ]; then
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
            echo "ERROR: PulseAudio socket not found after ${MAX_RETRIES} seconds"
            exit 1
        fi
        sleep 1
    done

    # Verify PulseAudio connection
    if [ -S "/run/pulse/native" ]; then
        echo "PulseAudio socket found at /run/pulse/native"
    else
        echo "ERROR: PulseAudio socket not available"
        exit 1
    fi

    PA_SOURCE="default"
    echo "Using PulseAudio source: $PA_SOURCE"
    AUDIO_ARGS=(-f pulse -i "$PA_SOURCE")
fi

# Start Icecast in background
echo "Starting Icecast server..."
icecast2 -c "$ICECAST_CONFIG" -b
sleep 2

# Verify Icecast is running
if ! curl -s http://localhost:8888/status-json.xsl > /dev/null 2>&1; then
    echo "ERROR: Icecast failed to start"
    exit 1
fi

echo "Icecast server started on port 8888"

# Retry configuration (match main container patterns)
if [ -n "$RTSP_STREAM_URL" ]; then
    RETRY_DELAY=2  # RTSP needs longer reconnection time
else
    RETRY_DELAY=1  # PulseAudio recovers faster
fi
RETRY_COUNT=0
LAST_ERROR_LOG=0
ERROR_LOG_INTERVAL=30
FFMPEG_PID=""

# Graceful shutdown handler
RUNNING=true
cleanup() {
    RUNNING=false
    echo "[$(date '+%H:%M:%S')] Received shutdown signal..."
    if [ -n "$FFMPEG_PID" ]; then
        kill "$FFMPEG_PID" 2>/dev/null || true
    fi
}
trap cleanup SIGTERM SIGINT

# Disable exit-on-error for the retry loop
set +e

echo "[$(date '+%H:%M:%S')] Starting audio stream capture..."

while $RUNNING; do
    STREAM_START=$(date +%s)

    ffmpeg -hide_banner -loglevel warning \
        "${AUDIO_ARGS[@]}" \
        -codec:a libmp3lame -b:a "$STREAM_BITRATE" \
        -f mp3 -content_type audio/mpeg \
        "icecast://source:${ICECAST_PASSWORD}@localhost:8888/stream.mp3" &
    FFMPEG_PID=$!

    # Log successful start after brief delay (FFmpeg connects quickly if source is available)
    sleep 1
    if kill -0 "$FFMPEG_PID" 2>/dev/null; then
        if [ "$RETRY_COUNT" -gt 0 ]; then
            echo "[$(date '+%H:%M:%S')] Stream reconnected after $RETRY_COUNT retries"
        else
            echo "[$(date '+%H:%M:%S')] Stream connected successfully"
        fi
        RETRY_COUNT=0
    fi

    wait "$FFMPEG_PID"
    EXIT_CODE=$?
    STREAM_DURATION=$(($(date +%s) - STREAM_START))

    if ! $RUNNING; then
        echo "[$(date '+%H:%M:%S')] Shutdown complete"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))

    # Rate-limited error logging (avoid log flooding)
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - LAST_ERROR_LOG)) -gt "$ERROR_LOG_INTERVAL" ]; then
        LAST_ERROR_LOG=$CURRENT_TIME
        if [ "$STREAM_DURATION" -gt 5 ]; then
            echo "[$(date '+%H:%M:%S')] Stream disconnected after ${STREAM_DURATION}s (exit code: $EXIT_CODE), reconnecting..."
        else
            echo "[$(date '+%H:%M:%S')] Connection failed (attempt $RETRY_COUNT), retrying in ${RETRY_DELAY}s..."
        fi
    fi

    sleep "$RETRY_DELAY"
done
