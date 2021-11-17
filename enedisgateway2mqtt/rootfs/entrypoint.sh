#!/bin/bash

###################################
# Export all addon options as env #
###################################

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables 
mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})
for KEYS in ${arr[@]}; do
        # export key
        export $(echo "${KEYS}=$(jq .$KEYS ${JSONSOURCE})")
        echo "${KEYS}=$(jq .$KEYS ${JSONSOURCE})"
done 

####################
# Starting scripts #
####################

echo "Starting scripts :"
for SCRIPTS in scripts/*; do
  [ -e "$SCRIPTS" ] || continue
  echo "$SCRIPTS: executing"
  chown $(id -u):$(id -g) $SCRIPTS
  chmod a+x $SCRIPTS
  sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' $SCRIPTS || true
  ./$SCRIPTS || echo "$SCRIPTS: exiting $?"
done
