#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Allow advanced users to supply their own ALSA config (e.g. to enable JACK
# or a custom dsnoop chain) by dropping asound.conf into the addon config
# folder. Written to /root/.asoundrc because /etc/asound.conf is read-only.
if [ -f /config/asound.conf ]; then
    if [ -r /config/asound.conf ]; then
        bashio::log.info "Using user-provided /config/asound.conf, overriding addon defaults"
        if ! cp /config/asound.conf /root/.asoundrc; then
            bashio::log.warning "Failed to copy /config/asound.conf; continuing with bundled /root/.asoundrc defaults"
        fi
    else
        bashio::log.warning "/config/asound.conf exists but is not readable; continuing with bundled /root/.asoundrc defaults"
    fi
fi

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"
if bashio::config.true "homeassistant_microphone"; then
    bashio::log.info "homeassistant_microphone option is selected. The audio card config value is set to 'default'. Set in the addon options to which this is set"
    audio_card="default"
    yq -iy ".realtime.audio.source = \"${audio_card}\"" "$CONFIG_LOCATION"
else
    bashio::log.info "homeassistant_microphone option is not set, keeping audio source configured via the UI"
fi

# Skip the BirdNET-Go login under ingress with its own "Bypass Authentication":
# trust the ingress nginx (127.0.0.1) as a reverse proxy, so the verified client
# is the Supervisor (172.30.32.2), and let that one address bypass the login.
# Entries are merged, never overwritten; turning the option off removes the
# Supervisor entry and disables the bypass.
INGRESS_SUBNET="172.30.32.2/32"
SUBNETS='((.security.allowsubnetbypass.subnet // "") | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != "")))'
if bashio::config.true "INGRESS_SKIP_AUTH"; then
    bashio::log.warning "INGRESS_SKIP_AUTH: Home Assistant ingress skips the BirdNET-Go login (Settings > Security > Bypass Authentication)"
    yq -iy ".security.trustedproxies = ((.security.trustedproxies // []) | if index(\"127.0.0.1\") then . else . + [\"127.0.0.1\"] end)
        | .security.allowsubnetbypass.subnet = ($SUBNETS | if index(\"$INGRESS_SUBNET\") then . else . + [\"$INGRESS_SUBNET\"] end | join(\",\"))
        | .security.allowsubnetbypass.enabled = true" "$CONFIG_LOCATION"
elif [ "$(yq -r "$SUBNETS | index(\"$INGRESS_SUBNET\") != null" "$CONFIG_LOCATION")" = true ]; then
    bashio::log.info "INGRESS_SKIP_AUTH is off: removing $INGRESS_SUBNET and disabling Bypass Authentication"
    yq -iy ".security.allowsubnetbypass.subnet = ($SUBNETS | map(select(. != \"$INGRESS_SUBNET\")) | join(\",\"))
        | .security.allowsubnetbypass.enabled = false" "$CONFIG_LOCATION"
fi

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
# Persist the Intel GPU driver's kernel cache: compiling the models for the iGPU
# otherwise takes ~2 minutes on every start (the container is recreated each time)
export NEO_CACHE_DIR="${NEO_CACHE_DIR:-/config/cache/neo_compiler_cache}"
mkdir -p "$NEO_CACHE_DIR"
bashio::log.info "OpenVINO GPU models are compiled and cached in $NEO_CACHE_DIR: the first start, or the first start after installing a new model, can seem to hang for a few minutes while this happens"
# shellcheck disable=SC2086
/usr/bin/entrypoint.sh /usr/bin/startup-wrapper.sh birdnet-go realtime &
true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx
