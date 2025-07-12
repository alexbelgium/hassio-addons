#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

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
	if [[ "$CONFIGSOURCE" == *"."* ]]; then
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
		bashio::log.red "Watch-out: your CONFIG_LOCATION values can only be set in /share, /config or /data (internal to addon). It will be reset to the default location: $CONFIGLOCATION/config.yaml"
		CONFIGSOURCE="$CONFIGLOCATION"/config.yaml
	fi
fi

# Migrate if needed
if [[ "$CONFIGLOCATION" == "/config" ]]; then
	# Migrate file
	if [ -f "/homeassistant/addons_config/${slug}/config.yaml" ] && [ ! -L "/homeassistant/addons_config/${slug}" ]; then
		echo "Migrating config.yaml to new config location"
		mv "/homeassistant/addons_config/${slug}/config.yaml" /config/config.yaml
	fi
	# Migrate option
	if [[ "$(bashio::config "CONFIG_LOCATION")" == "/config/addons_config"* ]] && [ -f /config/config.yaml ]; then
		bashio::addon.option "CONFIG_LOCATION" "/config/config.yaml"
		CONFIGSOURCE="/config/config.yaml"
	fi
fi

if [[ "$CONFIGSOURCE" != *".yaml" ]]; then
	bashio::log.error "Something is going wrong in the config location, quitting"
	exit 1
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
bashio::log.green "Wiki here on how to use: https://github.com/alexbelgium/hassio-addons/wiki/Addons-feature:-add-env-variables"
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
echo "" >>/tempenv

# Exit if empty
if [ ! -s /tempenv ]; then
	bashio::log.green "... no env variables found, exiting"
	exit 0
fi

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed /tempenv &>ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	cat ERROR
	bashio::log.yellow "... config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
fi

# converts yaml to variables
sed -i 's/: /=/' /tempenv

# Look where secrets.yaml is located
SECRETSFILE="/config/secrets.yaml"
if [ ! -f "$SECRETSFILE" ]; then SECRETSFILE="/homeassistant/secrets.yaml"; fi

while IFS= read -r line; do
	# Skip empty lines
	if [[ -z "$line" ]]; then
		continue
	fi

	# Check if secret
	if [[ "$line" == *!secret* ]]; then
		echo "Secret detected"
		if [ ! -f "$SECRETSFILE" ]; then
			bashio::log.fatal "Secrets file not found in $SECRETSFILE, $line skipped"
			continue
		fi
		secret=$(echo "$line" | sed 's/.*!secret \(.*\)/\1/')
		# Check if single match
		secretnum=$(sed -n "/$secret:/=" "$SECRETSFILE")
		if [[ $(echo "$secretnum" | grep -q ' ') ]]; then
			bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
		fi
		# Get text
		secret_value=$(sed -n "/$secret:/s/.*: //p" "$SECRETSFILE")
		line="${line%%=*}='$secret_value'"
	fi

	# Data validation
	if [[ "$line" =~ ^[^[:space:]]+.+[=].+$ ]]; then
		# extract keys and values
		KEYS="${line%%=*}"
		VALUE="${line#*=}"
		# Check if VALUE is quoted
		#if [[ "$VALUE" != \"*\" ]] && [[ "$VALUE" != \'*\' ]]; then
		#	VALUE="\"$VALUE\""
		#fi
		line="${KEYS}=${VALUE}"
		export "$line"
		# export to python
		if command -v "python3" &>/dev/null; then
			[ ! -f /env.py ] && echo "import os" >/env.py
			# Escape single quotes in VALUE
			VALUE_ESCAPED="${VALUE//\'/\'\"\'\"\'}"
			echo "os.environ['${KEYS}'] = '${VALUE_ESCAPED}'" >>/env.py
			python3 /env.py
		fi
		# set .env
		echo "$line" >>/.env
		# set environment
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
		bashio::log.red "Skipping line that does not follow the correct structure: $line"
	fi
done <"/tempenv"

rm /tempenv
