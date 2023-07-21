#!/bin/bash
echo "Starting..."

############################
# Backup Dockerfile Script #
############################

if [ -f /etc/cont-init.d/00-aaa_dockerfile_backup.sh ]; then
    chown "$(id -u)":"$(id -g)" /etc/cont-init.d/00-aaa_dockerfile_backup.sh
    chmod +x /etc/cont-init.d/00-aaa_dockerfile_backup.sh
    /./etc/cont-init.d/00-aaa_dockerfile_backup.sh
    rm /etc/cont-init.d/00-aaa_dockerfile_backup.sh
fi

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
