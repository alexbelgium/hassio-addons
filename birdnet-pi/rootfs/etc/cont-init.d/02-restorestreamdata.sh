#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Check if the /data/StreamData directory exists
if [ -d /data/StreamData ]; then

    # Check specifically for any .wav files in the directory
    wav_file_exists=$(find /data/StreamData -type f -name "*.wav" -print -quit)

    # If a .wav file is found
    if [ -n "$wav_file_exists" ]; then
        # Count the number of .wav files in /data/StreamData
        wav_count=$(find /data/StreamData -type f -name "*.wav" | wc -l)
        bashio::log.warning "Container was stopped while files were still being analyzed, restoring $wav_count .wav files"

        # Move files if there are any .wav files
        if [ "$wav_count" -gt 0 ]; then
            mv -v /data/StreamData/*.wav "$HOME"/BirdSongs/StreamData/
        fi

        echo "... done"
        echo ""

        # Setting permissions
        chown -R pi:pi "$HOME"/BirdSongs
        chmod -R 755 "$HOME"/BirdSongs
    fi

    # Cleaning folder only if the directory exists (in case it was modified)
    rm -r /data/StreamData
fi
