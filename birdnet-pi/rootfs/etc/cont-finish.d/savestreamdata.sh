#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Maximum file size in bytes (50MB)
MAX_SIZE=$((50 * 1024 * 1024))

# Function to check if a file is a valid WAV
is_valid_wav() {
  local file="$1"
  # Check if the file contains a valid WAV header
  file "$file" | grep -qE 'WAVE audio'
}

if [ -d "$HOME"/BirdSongs/StreamData ]; then
  bashio::log.fatal "Container stopping, saving temporary files."

  # Stop the services in parallel
  if systemctl is-active --quiet birdnet_analysis; then
    bashio::log.info "Stopping birdnet_analysis service."
    systemctl stop birdnet_analysis &
  fi

  if systemctl is-active --quiet birdnet_recording; then
    bashio::log.info "Stopping birdnet_recording service."
    systemctl stop birdnet_recording &
  fi

  # Wait for both services to stop
  wait

  # Create the destination directory
  mkdir -p /config/TemporaryFiles

  # Move only valid WAV files under 50MB
  shopt -s nullglob # Prevent errors if no files match
  for file in "$HOME"/BirdSongs/StreamData/*.wav; do
    if [ -f "$file" ] && [ "$(stat --format="%s" "$file")" -lt "$MAX_SIZE" ] && is_valid_wav "$file"; then
      if mv -v "$file" /config/TemporaryFiles/; then
        bashio::log.info "Moved valid WAV file: $(basename "$file")"
      else
        bashio::log.error "Failed to move: $(basename "$file")"
      fi
    else
      bashio::log.warning "Skipping invalid or large file: $(basename "$file")"
    fi
  done

  bashio::log.info "... files safe, allowing container to stop."
else
  bashio::log.info "No StreamData directory to process."
fi
