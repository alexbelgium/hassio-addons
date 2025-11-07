#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##################
# INITIALIZATION #
##################

# Disable if config not present
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
    chmod -R 755 "$(dirname "${CONFIGSOURCE}")" 2> /dev/null
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
bashio::log.notice "This script is used to export custom environment variables at start of the addon. Instructions here : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon"
bashio::log.warning "This methodology is deprecated. Environment variables can be added from the addon options using env_vars. Instructions can be found here : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
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
echo "" >> /tempenv

# Exit if empty
if [ ! -s /tempenv ]; then
    bashio::log.green "... no env variables found, exiting"
    exit 0
fi

# Duplicate sanitized yaml for addon options handling
cp /tempenv /tempenv_options
COMMENT_KEYS=()

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed /tempenv &> ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
    cat ERROR
    bashio::log.yellow "... config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
fi

# converts yaml to variables
sed -i 's/: /=/' /tempenv

# Duplicate conversion for addon options file
if [ -f /tempenv_options ]; then
    sed -i 's/: /=/' /tempenv_options
fi

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
        if command -v "python3" &> /dev/null; then
            [ ! -f /env.py ] && echo "import os" > /env.py
            # Escape single quotes in VALUE
            VALUE_ESCAPED="${VALUE//\'/\'\"\'\"\'}"
            echo "os.environ['${KEYS}'] = '${VALUE_ESCAPED}'" >> /env.py
            python3 /env.py
        fi
        # set .env
        echo "$line" >> /.env
        # set environment
        mkdir -p /etc
        echo "$line" >> /etc/environment
        # Export to scripts
        if cat /etc/services.d/*/*run* &> /dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2> /dev/null; fi
        if cat /etc/cont-init.d/*run* &> /dev/null; then sed -i "1a export $line" /etc/cont-init.d/*run* 2> /dev/null; fi
        # For s6
        if [ -d /var/run/s6/container_environment ]; then printf "%s" "${VALUE}" > /var/run/s6/container_environment/"${KEYS}"; fi
        echo "export $line" >> ~/.bashrc
        # Show in log
        if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
    else
        bashio::log.red "Skipping line that does not follow the correct structure: $line"
    fi
done < "/tempenv"

# Export yaml content to addon options env_vars
ENV_INDEX=0
if [ -f /tempenv_options ]; then
    existing_env_vars_json="$(bashio::addon.option 'env_vars' 2> /dev/null || true)"
    if [[ -z "$existing_env_vars_json" || "$existing_env_vars_json" == "null" ]]; then
        bashio::addon.option "env_vars" "[]"
    else
        existing_count="$(echo "$existing_env_vars_json" | jq 'length' 2> /dev/null || echo '')"
        if [[ "$existing_count" =~ ^[0-9]+$ ]]; then
            ENV_INDEX="$existing_count"
        else
            while true; do
                existing_name="$(bashio::addon.option "env_vars[$ENV_INDEX].name" 2> /dev/null || true)"
                existing_value="$(bashio::addon.option "env_vars[$ENV_INDEX].value" 2> /dev/null || true)"
                if [[ -z "$existing_name" && -z "$existing_value" ]]; then
                    break
                fi
                ENV_INDEX=$((ENV_INDEX + 1))
            done
        fi
    fi
    while IFS= read -r option_line; do
        # Skip empty lines
        if [[ -z "$option_line" ]]; then
            continue
        fi

        option_processed="$option_line"

        if [[ "$option_processed" =~ ^[^[:space:]]+.+[=].+$ ]]; then
            option_key="${option_processed%%=*}"
            option_value="${option_processed#*=}"

            # Trim surrounding whitespace
            option_key="$(printf '%s' "$option_key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            option_value="$(printf '%s' "$option_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

            if [[ -z "$option_key" ]]; then
                bashio::log.yellow "Skipping addon options export line without a valid key: $option_processed"
                continue
            fi

            # Remove matching quotes
            first_char="${option_value:0:1}"
            last_char="${option_value: -1}"
            if [[ "$first_char" == '"' && "$last_char" == '"' ]]; then
                option_value="${option_value:1:-1}"
            elif [[ "$first_char" == "'" && "$last_char" == "'" ]]; then
                option_value="${option_value:1:-1}"
            fi

            bashio::addon.option "env_vars[$ENV_INDEX].name" "$option_key"
            bashio::addon.option "env_vars[$ENV_INDEX].value" "$option_value"
            COMMENT_KEYS+=("$option_key")
            ENV_INDEX=$((ENV_INDEX + 1))
        else
            bashio::log.yellow "Skipping addon options export line that does not follow the correct structure: $option_processed"
        fi
    done < "/tempenv_options"
fi

if [[ -f "$CONFIGSOURCE" && ${#COMMENT_KEYS[@]} -gt 0 ]]; then
    if command -v python3 &> /dev/null; then
        python3 - "$CONFIGSOURCE" "${COMMENT_KEYS[@]}" <<'PYCODE'
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
keys = [key for key in sys.argv[2:] if key]
if not keys:
    sys.exit(0)

try:
    lines = config_path.read_text(encoding='utf-8').splitlines(keepends=True)
except Exception:
    sys.exit(0)

pending = set(keys)
updated = False
for index, line in enumerate(lines):
    stripped = line.lstrip()
    leading = line[: len(line) - len(stripped)]
    if stripped.startswith('#'):
        continue
    for key in list(pending):
        if stripped.startswith(f"{key}:"):
            lines[index] = f"{leading}# {stripped}"
            pending.remove(key)
            updated = True
            break

if updated:
    config_path.write_text(''.join(lines), encoding='utf-8')
PYCODE
    else
        bashio::log.yellow "python3 not available, unable to comment config entries synced to env_vars"
    fi
fi

rm /tempenv
rm -f /tempenv_options
