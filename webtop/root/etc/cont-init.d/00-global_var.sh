#!/bin/bash

###################################
# Export all addon options as env #
###################################

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})
for KEYS in ${arr[@]}; do
  # export key
  VALUE=$(jq .$KEYS ${JSONSOURCE})
  line="${KEYS}=${VALUE//[\"\']/} &>/dev/null"
  # Use locally
  export $line
  # Export the variable to run scripts
  sed -i "1a export $line" /etc/services.d/*/*run* 2>/dev/null || sed -i "1a export $line" /scripts/*run*
done

################
# Set timezone #
################
if [ ! -z "TZ" ] && [ -f /etc/localtime ]; then
  if [ -f /usr/share/zoneinfo/$TZ ]; then
    echo "Timezone set from $(cat /etc/timezone) to $TZ"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
  fi
fi
