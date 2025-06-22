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
# CHECK BIRDNET.CONF #
######################

bashio::log.info "Checking your birdnet.conf file integrity"

# Set variables
configcurrent="$HOME"/BirdNET-Pi/birdnet.conf
configtemplate="$HOME"/BirdNET-Pi/birdnet.bak

# Ensure both files exist before proceeding
if [ ! -f "$configcurrent" ] || [ ! -f "$configtemplate" ]; then
	bashio::log.fatal "Missing required birdnet.conf or birdnet.bak file. Please ensure both are present."
	exit 1
fi

# Extract variable names from config template and read each one
grep -o '^[^#=]*=' "$configtemplate" | sed 's/=//' | while read -r var; do
	# Check if the variable is in configcurrent, if not, append it
	if ! grep -q "^$var=" "$configcurrent"; then
		bashio::log.warning "...$var was missing from your birdnet.conf file, it was re-added"
		grep "^$var=" "$configtemplate" >>"$configcurrent"
	fi
	# Check for duplicates
	if [ "$(grep -c "^$var=" "$configcurrent")" -gt 1 ]; then
		bashio::log.error "Duplicate variable $var found in $configcurrent, all were commented out except for the first one"
		sed -i "0,/^$var=/!s/^$var=/#$var=/" "$configcurrent"
	fi
done

##############
# CHECK PORT #
##############

if [[ "$(bashio::addon.port "80")" == 3000 ]]; then
	bashio::log.fatal "This is crazy but your port is set to 3000 and streamlit doesn't accept this port! You need to change it from the addon options and restart. Thanks"
	sleep infinity
fi

##################
# PERFORM UPDATE #
##################

bashio::log.info "Performing potential updates"

# Adapt update_birdnet_snippets
sed -i "s|systemctl list-unit-files|false \&\& echo|g" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh # Avoid systemctl
sed -i "/systemctl /d" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh                                 # Avoid systemctl
sed -i "/install_tmp_mount/d" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh                          # Use HA tmp
sed -i "/find /d" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh                                      # Not useful
sed -i "/set -x/d" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh                                     # Not useful
sed -i "/restart_services/d" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh                           # Not useful
sed -i "s|/etc/birdnet/birdnet.conf|/config/birdnet.conf|g" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh
sed -i "/update_caddyfile/c echo \"yes\"" "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh # Avoid systemctl

# Execute update_birdnet_snippets
export RECS_DIR="$HOME/BirdSongs"
export EXTRACTED="$HOME/BirdSongs/Extracted"
chmod +x "$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh
"$HOME"/BirdNET-Pi/scripts/update_birdnet_snippets.sh
