#!/bin/sh
set -e

##########################################
# Global modifications before entrypoint #
##########################################

# Ensure lf
###########

for folders in /default /defaults /etc; do
  if [ -d "$folders" ]; then
    find "$folders" -type f -not -path '*/\.*' -exec grep -Il '.' {} \; | xargs -d '\n' -L 1 dos2unix -k
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
