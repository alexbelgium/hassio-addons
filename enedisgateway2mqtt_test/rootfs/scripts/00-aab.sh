#!/bin/bash

##########################
# Read all addon options #
##########################

# For all keys in options.json
JSONSOURCE="/data/options.json"
mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})

# Export keys as env variables
for KEYS in ${arr[@]}; do
        # export key
        export $(echo "${KEYS}=$(jq .$KEYS ${JSONSOURCE})")
done 
