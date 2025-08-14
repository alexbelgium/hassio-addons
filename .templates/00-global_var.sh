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
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

# Escape special characters using printf
sanitize_variable() {
    local raw="$1" # original value
    # printf %q escapes characters for safe shell usage
    printf '%q' "$raw"
}

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq -r --raw-output ".\"$KEYS\"" "$JSONSOURCE")
    # Check if the value is an array
    if [[ "$VALUE" == \[* ]]; then
        bashio::log.warning "One of your option is an array, skipping"
    else
        # Store raw and escaped variants
        VALUE_ESCAPED=$(sanitize_variable "$VALUE")
        line_raw="${KEYS}=${VALUE}"
        line_escaped="${KEYS}=${VALUE_ESCAPED}"

        # Check if secret
        if [[ "${line_raw}" == *"!secret "* ]]; then
            echo "secret detected"
            # Get argument
            secret=${line_raw#*secret }
            # Remove trailing ' or "
            secret="${secret%[\"\']}"
            # Stop if secret file not mounted
            if [[ "$SECRETSOURCE" == "false" ]]; then
                bashio::log.warning "Homeassistant config not mounted, secrets are not supported"
                continue
            fi
            # Check if single match
            secretnum=$(sed -n "/$secret:/=" "$SECRETSOURCE")
            [[ "$secretnum" == *' '* ]] && bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
            # Get text
            secret=$(sed -n "/$secret:/p" "$SECRETSOURCE")
            secret=${secret#*: }
            line_raw="${line_raw%%=*}='$secret'"
            VALUE="$secret"
            VALUE_ESCAPED=$(sanitize_variable "$VALUE")
            line_escaped="${line_raw%%=*}=${VALUE_ESCAPED}"
        fi

        # Log value
        if bashio::config.false "verbose" || [[ "${KEYS,,}" == *"pass"* ]]; then
            bashio::log.blue "${KEYS}=******"
        else
            bashio::log.blue "$line_raw"
        fi

        ######################################
        # Export the variable to run scripts #
        ######################################
        # shellcheck disable=SC2163
        export "${line_raw}"

        # export to python
        if command -v "python3" &> /dev/null; then
            [ ! -f /env.py ] && echo "import os" > /env.py
            # Escape \
            VALUEPY="${VALUE//\\/\\\\}"
            # Avoid " and '
            VALUEPY="${VALUEPY//[\"\']/}"
            echo "os.environ['${KEYS}'] = '$VALUEPY'" >> /env.py
            python3 /env.py
        fi

        # set .env
        echo "$line_raw" >> /.env || true
        # set /etc/environment
        mkdir -p /etc
        echo "$line_raw" >> /etc/environment
        # For non s6
        if cat /etc/services.d/*/*run* &> /dev/null; then sed -i "1a export $line_escaped" /etc/services.d/*/*run* 2> /dev/null; fi
        if cat /etc/cont-init.d/*.sh &> /dev/null; then sed -i "1a export $line_escaped" /etc/cont-init.d/*.sh 2> /dev/null; fi
        # For s6
        if [ -d /var/run/s6/container_environment ]; then printf "%s" "${VALUE}" > /var/run/s6/container_environment/"${KEYS}"; fi
        echo "export ${KEYS}='${VALUE_ESCAPED}'" >> ~/.bashrc
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
