#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Check if there are files in "$HOME"/BirdSongs/StreamData and move them to /data/StreamData
if [ -d /data/StreamData ] && [ "$(ls -A /data/StreamData/)" ]; then

    # Count the number of .wav files in /data/StreamData
    wav_count=$(find /data/StreamData -type f -name "*.wav" | wc -l)
    bashio::log.warning "Container was stopped while files were still being analyzed, restoring $wav_count .wav files"

    # Copy files
    if [ "$wav_count" -gt 0 ]; then
        mv -v /data/StreamData/* "$HOME"/BirdSongs/StreamData/
    fi

    echo "... done"
    echo ""

    # Setting permissions
    chown -R pi:pi "$HOME"/BirdSongs
    chmod -R 755 "$HOME"/BirdSongs

    # Cleaning folder
    rm -r /data/StreamData

fi
