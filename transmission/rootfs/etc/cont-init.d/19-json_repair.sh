!/bin/bash

JSONTOCHECK='/config/transmission/settings.json'
JSONSOURCE='/defaults/settings.json'

# If json already exists
if [ -f ${JSONTOCHECK} ]; then
    # Variables
    echo "Checking settings.json format"

    # Get the default keys from the original file
    mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})

    # Check if all keys are still there, or add them
    for KEYS in ${arr[@]}; do
        KEYSTHERE=$(jq "has(\"${KEYS}\")" ${JSONTOCHECK})
        [ $KEYSTHERE != "true" ] && sed -i "3 i\"${KEYS}\": null," ${JSONTOCHECK} && echo "... $KEYS was missing, added"
    done

    # Show structure in a nice way
    jq . -S ${JSONTOCHECK} | cat >temp.json && mv temp.json ${JSONTOCHECK}
fi

# Repair structure
################
#jq . -S $CONFIGDIR/settings.json | cat >temp.json && mv temp.json $CONFIGDIR/settings.json
#echo "Making sure settings.json structure is good"
#for KEYS in "incomplete-dir" "download-dir" "rpc-host-whitelist-enabled" "rpc-authentication-required" "rpc-username" "rpc-password" "rpc-whitelist-enabled" "rpc-whitelist"; do
#  KEYSTHERE=$(jq "has(\"${KEYS}\")" $CONFIGDIR/settings.json)
#  [ $KEYSTHERE != "true" ] && sed -i "3 i\"${KEYS}\": null," $CONFIGDIR/settings.json && echo "... $KEYS was missing, added"
#done
#jq . -S $CONFIGDIR/settings.json | cat >temp.json && mv temp.json $CONFIGDIR/settings.json
