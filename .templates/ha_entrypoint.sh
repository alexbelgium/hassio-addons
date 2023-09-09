#!/command/with-contenv bashio
# shellcheck shell=bash
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
    /usr/bin/env bashio "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    rm "$SCRIPTS"
done

######################
# Starting container #
######################

echo " "
echo -e "\033[0;32mStarting the upstream container\033[0m"
echo " "

# Launch lsio mods
if [ -f /docker-mods ]; then exec /docker-mods; fi
