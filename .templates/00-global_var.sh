#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if ! bashio::supervisor.ping 2> /dev/null; then
    echo "..."
    exit 0
fi

###################################
# Export all addon options as env #
###################################

echo ""
bashio::log.green "Convert addon options to environment variables"
bashio::log.green "----------------------------------------------"
bashio::log.notice "This script converts all addon options to environment variables. Custom variables can be set using env_vars."
bashio::log.notice "Additional informations : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
echo ""

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Define secrets location
if [ -f /homeassistant/secrets.yaml ]; then
    SECRETSOURCE="/homeassistant/secrets.yaml"
elif [ -f /config/secrets.yaml ]; then
    SECRETSOURCE="/config/secrets.yaml"
else
    SECRETSOURCE="false"
fi

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

# Escape special characters using printf and enclose in double quotes
sanitize_variable() {
    local raw="$1"
    local escaped
    if [[ "$raw" == \[* ]]; then
        echo "One of your options is an array, skipping"
        return
    fi
    printf -v escaped '%q' "$raw"
    # Do not espace spaces
    escaped="${escaped//\\ / }"
    if [[ "$raw" == "$escaped" ]]; then
        printf '%s' "$raw"
    else
        printf '%s' "$escaped"
    fi
}

export_option() {
    local key="$1"
    local value="$2"
    local line secret secretnum valuepy

    value=$(sanitize_variable "$value")

    if [[ -z "$value" ]]; then
        line="${key}=''"
    else
        line="${key}='${value//\'/\'\\\'\'}'"
    fi

    if [[ "${line}" == *"!secret "* ]]; then
        echo "secret detected"
        secret=${line#*secret }
        secret="${secret%[\"\']}"
        if [[ "$SECRETSOURCE" == "false" ]]; then
            bashio::log.warning "Homeassistant config not mounted, secrets are not supported"
            return
        fi
        secretnum=$(sed -n "/$secret:/=" "$SECRETSOURCE")
        [[ "$secretnum" == *' '* ]] && bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
        secret=$(sed -n "/$secret:/p" "$SECRETSOURCE")
        secret=${secret#*: }
        line="${line%%=*}='$secret'"
        value="$secret"
    fi

    if bashio::config.false "verbose" || [[ "${key,,}" == *"pass"* ]]; then
        bashio::log.blue "${key}=******"
    else
        bashio::log.blue "$line"
    fi

    export "$line"

    if command -v "python3" &> /dev/null; then
        [ ! -f /env.py ] && echo "import os" > /env.py
        valuepy="${value//\\/\\\\}"
        valuepy="${valuepy//[\"\']/}"
        echo "os.environ['${key}'] = '$valuepy'" >> /env.py
        python3 /env.py
    fi

    echo "$line" >> /.env || true
    mkdir -p /etc
    echo "$line" >> /etc/environment
    if cat /etc/services.d/*/*run* &> /dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2> /dev/null; fi
    if cat /etc/cont-init.d/*.sh &> /dev/null; then sed -i "1a export $line" /etc/cont-init.d/*.sh 2> /dev/null; fi
    if [ -d /var/run/s6/container_environment ]; then printf "%s" "${value}" > /var/run/s6/container_environment/"${key}"; fi
    echo "export ${key}='${value}'" >> ~/.bashrc
}

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq -r --raw-output ".\"$KEYS\"" "$JSONSOURCE")
    # Check if the value is an array
    if [[ "$VALUE" == \[* ]]; then
        if [[ "$KEYS" == "env_vars" ]]; then
            mapfile -t env_entries < <(jq -c ".\"$KEYS\"[]" "$JSONSOURCE")
            if [[ "${#env_entries[@]}" -eq 0 ]]; then
                continue
            fi
            env_processed=false
            for entry in "${env_entries[@]}"; do
                if [[ "$entry" == \{* ]]; then
                    env_name=$(jq -r 'if has("name") and has("value") then .name else empty end' <<< "$entry")
                    if [[ -n "$env_name" ]]; then
                        env_value=$(jq -r '.value // empty' <<< "$entry")
                        export_option "$env_name" "$env_value"
                        env_processed=true
                        continue
                    fi

                    # Preserve multiline values: iterate keys and extract raw values without @tsv
                    mapfile -t env_keys < <(jq -r 'keys[]' <<< "$entry")
                    for env_key in "${env_keys[@]}"; do
                        # Use --arg to select the key; // empty to avoid "null"
                        env_value=$(jq -r --arg k "$env_key" '.[$k] // empty' <<< "$entry")
                        export_option "$env_key" "$env_value"
                        env_processed=true
                    done
                elif [[ "${entry:0:1}" == '"' ]]; then
                    env_pair=$(jq -r '.' <<< "$entry")
                    if [[ "$env_pair" == *=* ]]; then
                        env_key=${env_pair%%=*}
                        env_value=${env_pair#*=}
                        export_option "$env_key" "$env_value"
                        env_processed=true
                    else
                        bashio::log.warning "env_vars entry '$env_pair' is not in KEY=VALUE format, skipping"
                    fi
                else
                    bashio::log.warning "env_vars entry format not supported, skipping"
                fi
            done
            if [[ "$env_processed" == false ]]; then
                bashio::log.warning "env_vars option format not supported, skipping"
            fi
        else
            bashio::log.warning "One of your option is an array, skipping"
        fi
    else
        export_option "$KEYS" "$VALUE"
    fi
done

################
# Set timezone #
################
set +eu

if [ -n "$TZ" ] && [ -f /etc/localtime ]; then
    if [ -f /usr/share/zoneinfo/"$TZ" ]; then
        echo "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
    fi
fi
