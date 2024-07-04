#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

######################
# CHECK BIRDNET.CONF #
######################

echo " "
bashio::log.info "Checking your birndet.conf file integrity"

# Set variables
configcurrent="$HOME"/BirdNET-Pi/birdnet.conf
configtemplate="$HOME"/BirdNET-Pi/birdnet.bak

# Extract variable names from config template and read each one
grep -o '^[^#=]*=' "$configtemplate" | sed 's/=//' | while read -r var; do
    # Check if the variable is in configcurrent, if not, append it
    if ! grep -q "^$var=" "$configcurrent"; then
        # At which line was the variable in the initial file
        bashio::log.yellow "...$var was missing from your birdnet.conf file, it was re-added"
        grep "^$var=" "$configtemplate" >> "$configcurrent"
    fi
    # Check for duplicates
    if [ "$(grep -c "^$var=" "$configcurrent")" -gt 1 ]; then
        bashio::log.error "Duplicate variable $var found in $configcurrent, all were commented out expect for the first one"
        awk -v var="$var" '{ if ($0 ~ "^[[:blank:]]*"var && c++ > 0) print "#" $0; else print $0; }' "$configcurrent" > temp && mv temp "$configcurrent"
    fi
done

################
# CHECK AMIXER #
################

# If default capture is set at 0%, increase it to 50%
current_volume="$(amixer sget Capture | grep -oP '\[\d+%]' | tr -d '[]%' | head -1)" 2>/dev/null || true
current_volume="${current_volume:-100}"

# Set the default microphone volume to 50% if it's currently at 0%
if [[ "$current_volume" -eq 0 ]]; then
    amixer sset Capture 70%
    bashio::log.warning "Microphone was off, volume set to 70%."
fi

##############
# CHECK PORT #
##############

if [[ "$(bashio::addon.port "80")" == 3000 ]]; then
  bashio::log.fatal "This is crazy but your port is set to 3000 and streamlit doesn't accept this port! You need to change it from the addon options and restart. Thanks"
  sleep infinity
fi

echo " "
