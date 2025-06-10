#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
  mkdir -p /etc/scripts-init
  sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
  sed -i "/ rm/d" /ha_entrypoint.sh
  cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

######################
# RESTORE STREAMDATA #
######################

if [ -d /config/TemporaryFiles ]; then

  # Check if there are .wav files in /config/TemporaryFiles
  if find /config/TemporaryFiles -type f -name "*.wav" | grep -q .; then
    bashio::log.warning "Container was stopped while files were still being analyzed."
    echo "... restoring .wav files from /config/TemporaryFiles to $HOME/BirdSongs/StreamData."

    # Create the destination directory if it does not exist
    mkdir -p "$HOME"/BirdSongs/StreamData

    # Count the number of .wav files to be moved
    file_count=$(find /config/TemporaryFiles -type f -name "*.wav" | wc -l)
    echo "... found $file_count .wav files to restore."

    # Move the .wav files using `mv` to avoid double log entries
    mv -v /config/TemporaryFiles/*.wav "$HOME"/BirdSongs/StreamData/

    # Update permissions only if files were moved successfully
    if [ "$file_count" -gt 0 ]; then
      chown -R pi:pi "$HOME"/BirdSongs/StreamData
    fi

    echo "... $file_count files restored successfully."
  else
    echo "... no .wav files found to restore."
  fi

  # Clean up the source folder if it is empty
  rm -r /config/TemporaryFiles

fi
