#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# INITIALIZATION #
##################

# Exit if /config is not mounted or HA not used
if [ ! -d /config ] || ! bashio::supervisor.ping 2> /dev/null; then
    echo "..."
    exit 0
fi

# Define slug
slug="${HOSTNAME/-/_}"
slug="${slug#*_}"

# Check type of config folder
if [ ! -f /config/configuration.yaml ] && [ ! -f /config/configuration.json ]; then
    # New config location
    CONFIGLOCATION="/config"
    CONFIGFILEBROWSER="/addon_configs/${HOSTNAME/-/_}/$slug.sh"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_autoscripts"
    CONFIGFILEBROWSER="/homeassistant/addons_autoscripts/$slug.sh"
fi

# Default location
mkdir -p "$CONFIGLOCATION" || true
CONFIGSOURCE="$CONFIGLOCATION/$slug.sh"

bashio::log.green "Execute $CONFIGFILEBROWSER if existing"
bashio::log.green "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

# Download template if no script found and exit
if [ ! -f "$CONFIGSOURCE" ]; then
    TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/script.template"
    curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGSOURCE" || true
    exit 0
fi

# Convert scripts to linux
dos2unix "$CONFIGSOURCE" &> /dev/null || true
chmod +x "$CONFIGSOURCE"

# Get current shebang, if not available use another
currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$CONFIGSOURCE")"
if [ ! -f "${currentshebang%% *}" ]; then
    for shebang in "/command/with-contenv bashio" "/usr/bin/env bashio" "/usr/bin/bashio" "/bin/bash" "/bin/sh"; do if [ -f "${shebang%% *}" ]; then break; fi; done
    sed -i "s|$currentshebang|$shebang|g" "$CONFIGSOURCE"
fi

# Check if there is actual commands
while IFS= read -r line; do
    # Remove leading and trailing whitespaces
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Check if line is not empty and does not start with #
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        bashio::log.green "... script found, executing"
        /."$CONFIGSOURCE"
        break
    fi
done < "$CONFIGSOURCE"
