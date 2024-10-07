#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -d /data/StreamData ]; then
    bashio::log.fatal "Container was stopped while files were still being analyzed."

    # Check if there are .wav files in /data/StreamData
    if find /data/StreamData -type f -name "*.wav" | grep -q .; then
        bashio::log.warning "Restoring .wav files from /data/StreamData to $HOME/BirdSongs/StreamData."

        # Count the number of .wav files to be moved
        file_count=$(find /data/StreamData -type f -name "*.wav" | wc -l)
        echo "... found $file_count .wav files to restore."

        # Move the .wav files using `mv` to avoid double log entries
        mv -v /data/StreamData/*.wav "$HOME"/BirdSongs/StreamData/

    else
        echo "... no .wav files found to restore."
    fi

    # Clean up the source folder if empty
    rm -r /data/StreamData
fi
