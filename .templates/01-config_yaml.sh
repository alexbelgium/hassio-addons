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

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed /tempenv &> ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
    cat ERROR
    bashio::log.yellow "... config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
fi

# converts yaml to variables
sed -i 's/: /=/' /tempenv

# Look where secrets.yaml is located
SECRETSFILE="/config/secrets.yaml"
if [ ! -f "$SECRETSFILE" ]; then SECRETSFILE="/homeassistant/secrets.yaml"; fi

existing_env_vars_json=$(bashio::jq "$(bashio::addon.options)" '.env_vars // []')
if [[ -z "${existing_env_vars_json}" ]] || [[ "${existing_env_vars_json}" == "null" ]]; then
    existing_env_vars_json='[]'
fi

declare -A __env_var_new_map
declare -a __env_var_new_keys
declare -A __env_var_processed_keys
declare -a __env_var_processed_order

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
        # Track processed keys and values for migration to env_vars
        key_clean="${KEYS}"
        key_clean="${key_clean#"${key_clean%%[![:space:]]*}"}"
        key_clean="${key_clean%"${key_clean##*[![:space:]]}"}"
        value_clean="${VALUE}"
        value_clean="${value_clean#"${value_clean%%[![:space:]]*}"}"
        if [[ -n "${key_clean}" ]]; then
            if [[ -z "${__env_var_new_map["${key_clean}"]}" ]]; then
                __env_var_new_keys+=("${key_clean}")
            fi
            __env_var_new_map["${key_clean}"]="${key_clean}=${value_clean}"
            if [[ -z "${__env_var_processed_keys["${key_clean}"]}" ]]; then
                __env_var_processed_keys["${key_clean}"]=1
                __env_var_processed_order+=("${key_clean}")
            fi
        fi
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

if [[ ${#__env_var_new_keys[@]} -gt 0 ]]; then
    __env_var_new_payload=""
    for key in "${__env_var_new_keys[@]}"; do
        __env_var_new_payload+="${__env_var_new_map["${key}"]}"$'\n'
    done
    if [[ -n "${__env_var_new_payload}" ]]; then
        read -r -d '' __env_var_new_entries_filter <<'JQ' || true
def trim: sub("^\\s+";"") | sub("\\s+$";"");
def strip_wrapping_quotes:
    if (startswith("\"") and endswith("\"") and (length >= 2)) then
        .[1:-1]
    elif (startswith("'") and endswith("'") and (length >= 2)) then
        .[1:-1]
    else
        .
    end;
[
  inputs
  | select(length > 0)
  | capture("(?<name>[^=]+)=(?<value>.*)")
  | { name: (.name | trim), value: (.value | trim | strip_wrapping_quotes) }
]
JQ
        new_entries_json=$(printf '%s' "${__env_var_new_payload}" | jq -Rcn "${__env_var_new_entries_filter}")
        if [[ -n "${new_entries_json}" ]] && [[ "${new_entries_json}" != "[]" ]]; then
            read -r -d '' jq_filter <<'JQ' || true
def key_of:
    if type == "string" then
        (split("=") | .[0])
    elif type == "object" then
        if has("name") then .name
        else (keys | .[0])
        end
    else
        null
    end;
($new | map(key_of)) as $new_keys |
($existing | map(select(
    (key_of) as $k |
    ($k != null and ($new_keys | index($k)) != null)
    | not
))) + $new
JQ
            merged_env_vars=$(jq -nc --argjson existing "${existing_env_vars_json}" --argjson new "${new_entries_json}" "${jq_filter}")
            bashio::addon.option "env_vars" "^${merged_env_vars}"
        fi
    fi
fi

if [[ ${#__env_var_processed_order[@]} -gt 0 ]] && [ -f "${CONFIGSOURCE}" ] && [ -w "${CONFIGSOURCE}" ]; then
    tmp_config_file=$(mktemp)
    if [[ -n "${tmp_config_file}" ]]; then
        while IFS= read -r original_line || [ -n "${original_line}" ]; do
            trimmed_line="${original_line#"${original_line%%[![:space:]]*}"}"
            if [[ -z "${trimmed_line}" ]]; then
                printf '%s\n' "${original_line}" >> "${tmp_config_file}"
                continue
            fi
            if [[ ${trimmed_line:0:1} == "#" ]]; then
                printf '%s\n' "${original_line}" >> "${tmp_config_file}"
                continue
            fi
            key_to_comment=""
            for processed_key in "${__env_var_processed_order[@]}"; do
                if [[ "${trimmed_line}" == "${processed_key}:"* ]]; then
                    key_to_comment="${processed_key}"
                    break
                fi
            done
            if [[ -n "${key_to_comment}" ]]; then
                indent="${original_line%"${trimmed_line}"}"
                printf '%s# %s\n' "${indent}" "${trimmed_line}" >> "${tmp_config_file}"
                printf '%s# Moved to env_vars configuration option.\n' "${indent}" >> "${tmp_config_file}"
            else
                printf '%s\n' "${original_line}" >> "${tmp_config_file}"
            fi
        done < "${CONFIGSOURCE}"
        mv "${tmp_config_file}" "${CONFIGSOURCE}"
    fi
fi

rm /tempenv
