#!/bin/bash
echo "Starting..."

####################
# Starting scripts #
####################

for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    echo "$SCRIPTS: executing"
    chown "$(id -u)":"$(id -g)" "$SCRIPTS"
    chmod a+x "$SCRIPTS"
    # Change shebang if no s6 supervision
    sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' "$SCRIPTS"
    /."$SCRIPTS" || echo "$SCRIPTS: exiting $?"
done
