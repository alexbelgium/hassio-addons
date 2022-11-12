#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

###################################
# Export all addon options as env #
###################################

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    # export key
    VALUE=$(jq ."$KEYS" "${JSONSOURCE}")
    line="${KEYS}='${VALUE//[\"\']/}'"
    # text
    if bashio::config.false "verbose" || [[ "${KEYS}" == *"PASS"* ]]; then
        bashio::log.blue "${KEYS}=******"
    else
        bashio::log.blue "$line"
    fi
    # Use locally
    export "${KEYS}='${VALUE//[\"\']/}'"
    # Export the variable to run scripts
    if cat /etc/services.d/*/*run* &>/dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2>/dev/null; fi
    if cat /etc/cont-init.d/*run* &>/dev/null; then sed -i "1a export $line" /etc/cont-init.d/*run* 2>/dev/null; fi

    # export on python
    if command -v "python3" &>/dev/null; then
      [ ! -f /env.py ] && echo "import os" > /env.py
      echo "os.environ['${line%%=*}'] = '${line#*=}'" >> /env.py
      python3 /env.py
      rm /env.py
    fi
done

################
# Set timezone #
################
set +e
if [ -n "$TZ" ] && [ -f /etc/localtime ]; then
    if [ -f /usr/share/zoneinfo/"$TZ" ]; then
        echo "Timezone set from $(cat /etc/timezone) to $TZ"
        ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone
    fi
fi
