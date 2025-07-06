#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC1087,SC2163,SC2116,SC2086
set -e

##################
# INITIALIZATION #
##################

# Disable if config not present
if [ ! -d /config ] || ! bashio::supervisor.ping 2>/dev/null; then
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
	CONFIGFILEBROWSER="/addon_configs/${HOSTNAME/-/_}/config.yaml"
else
	# Legacy config location
	CONFIGLOCATION="/config/addons_config/${slug}"
	CONFIGFILEBROWSER="/homeassistant/addons_config/$slug/config.yaml"
fi

# Default location
mkdir -p "$CONFIGLOCATION" || true
CONFIGSOURCE="$CONFIGLOCATION"/config.yaml

# Is there a custom path
if bashio::config.has_value 'CONFIG_LOCATION'; then

	CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
	if [[ "$CONFIGSOURCE" == *.* ]]; then
		CONFIGSOURCE=$(dirname "$CONFIGSOURCE")
	fi
	# If does not end by config.yaml, remove trailing slash and add config.yaml
	if [[ "$CONFIGSOURCE" != *".yaml" ]]; then
		CONFIGSOURCE="${CONFIGSOURCE%/}"/config.yaml
	fi
	# Check if config is located in an acceptable location
	LOCATIONOK=""
	for location in "/share" "/config" "/data"; do
		if [[ "$CONFIGSOURCE" == "$location"* ]]; then
			LOCATIONOK=true
		fi
	done
	if [ -z "$LOCATIONOK" ]; then
		bashio::log.red "Watch-out : your CONFIG_LOCATION values can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $CONFIGLOCATION/config.yaml"
		CONFIGSOURCE="$CONFIGLOCATION"/config.yaml
	fi
fi

# Migrate if needed
if [[ "$CONFIGLOCATION" == "/config" ]]; then
	# Migrate file
	if [ -f "/homeassistant/addons_config/${slug}/config.yaml" ] && [ ! -L "/homeassistant/addons_config/${slug}" ]; then
		echo "Migrating config.yaml to new config location"
		mv /homeassistant/addons_config/"${slug}"/config.yaml /config/config.yaml
	fi
	# Migrate option
	if [[ "$(bashio::config "CONFIG_LOCATION")" == "/config/addons_config"* ]] && [ -f /config/config.yaml ]; then
		bashio::addon.option "CONFIG_LOCATION" "/config/config.yaml"
		CONFIGSOURCE="/config/config.yaml"
	fi
fi

if [[ "$CONFIGSOURCE" != *".yaml" ]]; then
	bashio::log.error "Something is going wrong in the config location, quitting"
fi

# Permissions
if [[ "$CONFIGSOURCE" == *".yaml" ]]; then
	echo "Setting permissions for the config.yaml directory"
	mkdir -p "$(dirname "${CONFIGSOURCE}")"
	chmod -R 755 "$(dirname "${CONFIGSOURCE}")" 2>/dev/null
fi

####################
# LOAD CONFIG.YAML #
####################

echo ""
bashio::log.green "Load environment variables from $CONFIGSOURCE if existing"
if [[ "$CONFIGSOURCE" == "/config"* ]]; then
	bashio::log.green "If accessing the file with filebrowser it should be mapped to $CONFIGFILEBROWSER"
else
	bashio::log.green "If accessing the file with filebrowser it should be mapped to $CONFIGSOURCE"
fi
bashio::log.green "---------------------------------------------------------"
bashio::log.green "Wiki here on how to use : github.com/alexbelgium/hassio-addons/wiki/Add‐ons-feature-:-add-env-variables"
echo ""

# Check if config file is there, or create one from template
if [ ! -f "$CONFIGSOURCE" ]; then
	echo "... no config file, creating one from template. Please customize the file in $CONFIGSOURCE before restarting."
	# Create folder
	mkdir -p "$(dirname "${CONFIGSOURCE}")"
	# Placing template in config
	if [ -f /templates/config.yaml ]; then
		# Use available template
		cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"
	else
		# Download template
		TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/config.template"
		curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGSOURCE"
	fi
fi

# Check if there are lines to read
cp "$CONFIGSOURCE" /tempenv
sed -i '/^#/d' /tempenv
sed -i '/^[[:space:]]*$/d' /tempenv
sed -i '/^$/d' /tempenv
# Exit if empty
if [ ! -s /tempenv ]; then
	bashio::log.green "... no env variables found, exiting"
	exit 0
fi
rm /tempenv

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed "$CONFIGSOURCE" &>ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	cat ERROR
	bashio::log.yellow "... config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
fi

# Export all yaml entries as env variables
# Helper function
function parse_yaml {
	local input_file=$1
	local output_file=$2

	# Clear the output file if it already exists
	>"$output_file"

	# Process each line to escape special characters and format as needed
	while IFS= read -r line; do
		# Skip lines that are empty or only contain whitespace
		[[ -z "$line" ]] && continue

		# Replace the first occurrence of ": " with "="
		line=${line/: /=}

		# Escape special characters not within single quotes
		line=$(sed -E "s/([^'])([][\$\`\"\\!&;|<>])/\1\\\\\\2/g" <<<"$line")

		# Write to output file
		echo "$line" >>"$output_file"
	done <"$input_file"
}

# Get list of parameters in a file
parse_yaml "$CONFIGSOURCE" "" >/tmpfile
# Escape dollars
sed -i 's|$.|\$|g' /tmpfile

# Look where secrets.yaml is located
SECRETSFILE="/config/secrets.yaml"
if [ -f "$SECRETSFILE" ]; then SECRETSFILE="/homeassistant/secrets.yaml"; fi

while IFS= read -r line; do
	# Check if secret
	if [[ "${line}" == *'!secret '* ]]; then
		echo "secret detected"
		secret=${line#*secret }
		# Check if single match
		secretnum=$(sed -n "/$secret:/=" "$SECRETSFILE")
		[[ $(echo $secretnum) == *' '* ]] && bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
		# Get text
		secret=$(sed -n "/$secret:/p" "$SECRETSFILE")
		secret=${secret#*: }
		line="${line%%=*}='$secret'"
	fi
	# Data validation
	if [[ "$line" =~ ^.+[=].+$ ]]; then
		# extract keys and values
		KEYS="${line%%=*}"
		VALUE="${line#*=}"
		line="${KEYS}='${VALUE}'"
		export "$line"
		# export to python
		if command -v "python3" &>/dev/null; then
			[ ! -f /env.py ] && echo "import os" >/env.py
			echo "os.environ['${KEYS}'] = '${VALUE//[\"\']/}'" >>/env.py
			python3 /env.py
		fi
		# set .env
		if [ -f /.env ]; then echo "$line" >>/.env; fi
		mkdir -p /etc
		echo "$line" >>/etc/environment
		# Export to scripts
		if cat /etc/services.d/*/*run* &>/dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2>/dev/null; fi
		if cat /etc/cont-init.d/*run* &>/dev/null; then sed -i "1a export $line" /etc/cont-init.d/*run* 2>/dev/null; fi
		# For s6
		if [ -d /var/run/s6/container_environment ]; then printf "%s" "${VALUE}" >/var/run/s6/container_environment/"${KEYS}"; fi
		echo "export $line" >>~/.bashrc
		# Show in log
		if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
	else
		bashio::log.red "$line does not follow the correct structure. Please check your yaml file."
	fi
done <"/tmpfile"
