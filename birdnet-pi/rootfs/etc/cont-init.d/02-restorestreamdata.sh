#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -d /data/StreamData ]; then

    # Check if there are .wav files in /data/StreamData
    if find /data/StreamData -type f -name "*.wav" | grep -q .; then
        bashio::log.warning "Container was stopped while files were still being analyzed."
        echo "... restoring .wav files from /data/StreamData to $HOME/BirdSongs/StreamData."

        # Create the destination directory if it does not exist
        mkdir -p "$HOME"/BirdSongs/StreamData

        # Count the number of .wav files to be moved
        file_count=$(find /data/StreamData -type f -name "*.wav" | wc -l)
        echo "... found $file_count .wav files to restore."

        # Move the .wav files using `mv` to avoid double log entries
        mv -v /data/StreamData/*.wav "$HOME"/BirdSongs/StreamData/

        # Update permissions only if files were moved successfully
        if [ "$file_count" -gt 0 ]; then
            chown -R pi:pi "$HOME"/BirdSongs/StreamData
        fi

        echo "... $file_count files restored successfully."
    else
        echo "... no .wav files found to restore."
    fi

    # Clean up the source folder if it is empty
    if [ -z "$(ls -A /data/StreamData)" ]; then
        rm -r /data/StreamData
    fi
fi
