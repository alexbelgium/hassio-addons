#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define slug if needed
slug="${HOSTNAME#*-}"

# Check type of config folder
if [ ! -f /config/configuration.yaml ] && [ ! -f /config/configuration.json ]; then
    # Migrate previous script
    if [ -f /homeassistant/addons_autoscripts/"${slug}".sh ]; then
        echo "Migrating scripts to new config location"
        mv -f /homeassistant/addons_autoscripts/"${slug}".sh /config/"${slug}".sh
    fi
    # New config location
    CONFIGLOCATION="/config"
    CONFIGFILEBROWSER="/config/*-$slug"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_autoscripts"
    CONFIGFILEBROWSER="/config/addons_autoscripts"
    mkdir -p /config/addons_autoscripts
fi

bashio::log.green "Execute $CONFIGFILEBROWSER/${slug}.sh if existing"
bashio::log.green "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

# Download template if no script found and exit
if [ ! -f "$CONFIGLOCATION/${slug}".sh ]; then
    TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/script.template"
    curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGLOCATION/${slug}".sh
    exit 0
fi

# Convert scripts to linux
dos2unix "$CONFIGLOCATION/${slug}".sh &>/dev/null || true
chmod +x "$CONFIGLOCATION/${slug}".sh

# Check if there is actual commands
while IFS= read -r line
do
    # Remove leading and trailing whitespaces
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Check if line is not empty and does not start with #
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        bashio::log.green "... script found, executing"
        /."$CONFIGLOCATION/${slug}".sh
        exit 0
    fi
done < "$CONFIGLOCATION/${slug}".sh
