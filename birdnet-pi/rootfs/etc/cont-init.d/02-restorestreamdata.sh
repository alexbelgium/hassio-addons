#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -d /data/StreamData ]; then
    bashio::log.fatal "Container was stopped while files were still being analyzed."

    # Check if there are .wav files in /data/StreamData
    if find /data/StreamData -type f -name "*.wav" | grep -q .; then
        bashio::log.fatal "Restoring .wav files from /data/StreamData to $HOME/BirdSongs/StreamData."

        # Move the .wav files using `mv` to avoid double log entries
        mv -v /data/StreamData/*.wav "$HOME"/BirdSongs/StreamData/

        bashio::log.fatal "... files restored successfully, allowing container to stop."
    else
        bashio::log.info "No .wav files found to restore."
    fi

    # Clean up the source folder if empty
    rm -r /data/StreamData
fi
