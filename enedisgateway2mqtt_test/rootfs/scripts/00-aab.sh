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
done 
