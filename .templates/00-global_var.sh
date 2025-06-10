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
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq ."$KEYS" "${JSONSOURCE}")
    # Check if the value is an array
    if [[ $VALUE == \[*   ]]; then
        bashio::log.warning "One of your option is an array, skipping"
  else
        # Continue for single values
        VALUE="${VALUE//[\"\']/}"
        line="${KEYS}='${VALUE}'"
        # Check if secret
        if [[ ${line} == *"!secret "*   ]]; then
            echo "secret detected"
            # Get argument
            secret=${line#*secret }
            # Remove trailing ' or "
            secret="${secret%[\"\']}"
            # Stop if secret file not mounted
            if [[ $SECRETSOURCE == "false"   ]]; then
                bashio::log.warning "Homeassistant config not mounted, secrets are not supported"
                continue
      fi
            # Check if single match
            secretnum=$(sed -n "/$secret:/=" "$SECRETSOURCE")
            [[ $secretnum == *' '*   ]] && bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
            # Get text
            secret=$(sed -n "/$secret:/p" "$SECRETSOURCE")
            secret=${secret#*: }
            line="${line%%=*}='$secret'"
            VALUE="$secret"
    fi
        # text
        if bashio::config.false "verbose" || [[ ${KEYS,,} == *"pass"*   ]]; then
            bashio::log.blue "${KEYS}=******"
    else
            bashio::log.blue "$line"
    fi

        ######################################
        # Export the variable to run scripts #
        ######################################
        # shellcheck disable=SC2163
        export "$line"
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
        echo "$line" >> /.env || true
        # set /etc/environment
        mkdir -p /etc
        echo "$line" >> /etc/environment
        # For non s6
        if cat /etc/services.d/*/*run* &> /dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2> /dev/null; fi
        if cat /etc/cont-init.d/*run* &> /dev/null; then sed -i "1a export $line" /etc/cont-init.d/*run* 2> /dev/null; fi
        # For s6
        if [ -d /var/run/s6/container_environment ]; then printf "%s" "${VALUE}" > /var/run/s6/container_environment/"${KEYS}"; fi
        echo "export ${KEYS}='${VALUE}'" >> ~/.bashrc
  fi
done

################
# Set timezone #
################
set +e
if [ -n "$TZ" ] && [ -f /etc/localtime ]; then
    if [ -f /usr/share/zoneinfo/"$TZ" ]; then
        echo "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
  fi
fi
