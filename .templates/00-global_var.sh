#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

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
  VALUE=$(jq ."$KEYS" ${JSONSOURCE})
  line="${KEYS}=${VALUE//[\"\']/}"
  # Use locally
  if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
  # Export the variable to run scripts
  line="${KEYS}=${VALUE//[\"\']/} 2>/dev/null || true"
  if [ -f /etc/services.d/*/*run* ]; then sed -i "1a export $line" /etc/services.d/*/*run* 2>/dev/null; fi
  if [ -f /etc/cont-init.d/*run* ]; then sed -i "1a export $line" /etc/cont-init.d/*run* 2>/dev/null; fi
done

################
# Set timezone #
################
if [ -n "TZ" ] && [ -f /etc/localtime ]; then
  if [ -f /usr/share/zoneinfo/"$TZ" ]; then
    echo "Timezone set from $(cat /etc/timezone) to $TZ"
    ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone
  fi
fi
