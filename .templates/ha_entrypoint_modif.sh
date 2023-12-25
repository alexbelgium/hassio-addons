#!/bin/sh
set -e

##########################################
# Global modifications before entrypoint #
##########################################

# Ensure lf
###########

# This script recursively applies dos2unix to all files in /etc
# It skips hidden files, binary files, and files without crlf eol

# Find all non-hidden files in /etc that contain crlf eol
FILES=$(find /etc /defaults -type f -not -path '*/\.*' -exec grep -Il $'\r' {} \;)

# Loop through each file and apply dos2unix
for f in $FILES; do
  # Check if the file is a text file
  if file "$f" | grep -q text; then
    # Apply dos2unix and keep the original timestamp
    dos2unix -k "$f"
  fi
done

# Corrects permissions for s6 v3
################################

if [ -d /etc/cont-init.d ]; then
    chmod -R 755 /etc/cont-init.d
fi

if [ -d /etc/services.d ]; then
    chmod -R 755 /etc/services.d
fi

if [ -d /etc/s6-rc.d ]; then
    chmod -R 755 /etc/s6-rc.d
fi

# Correct shebang in entrypoint
###############################

# Make s6 contenv if needed
mkdir -p /run/s6/container_environment

# Check if shebang exists
for shebang in "/command/with-contenv bashio" "/usr/bin/env bashio" "/usr/bin/bashio" "/bin/bash" "/bin/sh"; do
    if [ -f "${shebang%% *}" ]; then
        break
    fi
done

# Define shebang
sed -i "s|/command/with-contenv bashio|$shebang|g" /ha_entrypoint.sh
