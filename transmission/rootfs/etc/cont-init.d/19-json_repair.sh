#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

JSONTOCHECK='/config/addons_config/transmission/settings.json'
JSONSOURCE='/defaults/settings.json'

# If json already exists
if [ -f "${JSONTOCHECK}" ]; then
    # Variables
    echo "Checking settings.json format"

    # Check if json file valid or not
    jq . -S "${JSONTOCHECK}" &>/dev/null && ERROR=false || ERROR=true
    if [ "$ERROR" = true ]; then
        bashio::log.fatal "Settings.json structure is abnormal, restoring options from scratch. Your old file is renamed as settings.json_old"
        mv "${JSONSOURCE}" "${JSONSOURCE}"_old
        cp "${JSONSOURCE}" "${JSONTOCHECK}"
        exit 0
  fi

    # Get the default keys from the original file
    mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

    # Check if all keys are still there, or add them
    # shellcheck disable=SC2086
    for KEYS in "${arr[@]}"; do
        # Check if key exists
        KEYSTHERE=$(jq "has(\"${KEYS}\")" "${JSONTOCHECK}")
        if [ "$KEYSTHERE" != "true" ]; then
            #Fetch initial value
            JSONSOURCEVALUE=$(jq -r ".\"$KEYS\"" "${JSONSOURCE}")
            #Add key
            sed -i "3 i\"${KEYS}\": \"${JSONSOURCEVALUE}\"," "${JSONTOCHECK}"
            # Message
            bashio::log.warning "${KEYS} was missing from your settings.json, it was added with the default value ${JSONSOURCEVALUE}"
    fi
  done

    # Show structure in a nice way
    jq . -S "${JSONTOCHECK}" | cat >temp.json && mv temp.json "${JSONTOCHECK}"

    # Message
    bashio::log.info "Your settings.json was checked and seems perfectly normal!"
fi

# Repair structure
################
#jq . -S $CONFIGDIR/settings.json | cat >temp.json && mv temp.json $CONFIGDIR/settings.json
#echo "Making sure settings.json structure is good"
#for KEYS in "incomplete-dir" "download-dir" "rpc-host-whitelist-enabled" "rpc-authentication-required" "rpc-username" "rpc-password" "rpc-whitelist-enabled" "rpc-whitelist"; do
#  KEYSTHERE=$(jq "has(\"${KEYS}\")" $CONFIGDIR/settings.json)
#  [ "$KEYSTHERE" != "true" ] && sed -i "3 i\"${KEYS}\": null," $CONFIGDIR/settings.json && echo "... $KEYS was missing, added"
#done
#jq . -S $CONFIGDIR/settings.json | cat >temp.json && mv temp.json $CONFIGDIR/settings.json
