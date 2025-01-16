#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Migrate files #
#################
if [ -f /data/birdnet.db ]; then
    bashio::log.warning "Moving db to /config"
    mv /data/birdnet.db /config
fi

# Audio clips location
birdsongsloc="$(bashio::config "BIRDSONGS_FOLDER")"
birdsongsloc="${birdsongsloc:-/config/clips}"
birdsongsloc="${birdsongsloc%/}"
mkdir -p "$birdsongsloc"
if [ -d /data/clips ]; then
    bashio::log.warning "Audio clips found in /data, moving to the new location"
    cp -rnf /data/clips/* "$birdsongsloc"/
    rm -r /data/clips
fi
ln -sf "$birdsongsloc" /data/clips

####################
# Correct defaults #
####################
bashio::log.info "Correct config for defaults"

# Database location
echo "... database location is /config/birdnet.db"
for configloc in /config/config.yaml /internal/conf/config.yaml; do
    if [ -f "$configloc" ]; then
        sed -i "s| birdnet.db| /config/birdnet.db|g" "$configloc"
    fi
done

# Birdsongs location
echo "... audio clips saved to $birdsongsloc"
for configloc in /config/config.yaml /internal/conf/config.yaml; do
    if [ -f "$configloc" ]; then
        sed -E "s|(.*path: ).*( #.*audio clip export directory.*)|\1$birdsongsloc\2|g" "$configloc"
    fi
done

# If default capture is set at 0%, increase it to 50%
current_volume="$(amixer sget Capture | grep -oP '\[\d+%]' | tr -d '[]%' | head -1)" 2>/dev/null || true
current_volume="${current_volume:-100}"
if [[ "$current_volume" -eq 0 ]]; then
    amixer sset Capture 70%
    bashio::log.warning "Microphone was off, volume set to 70%."
fi
