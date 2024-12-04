#!/command/with-contenv bashio
# shellcheck shell=bash

# Only trap SIGTERM if the script's PID is 1
if [ "$$" -eq 1 ]; then
    echo "PID is 1, trapping SIGTERM..."
    set -m
    terminate() {
        echo "Termination signal received, forwarding to subprocesses..."
        
        # Check for available commands to terminate subprocesses
        if command -v pkill &>/dev/null; then
            pkill -P $$
        elif command -v kill &>/dev/null; then
            kill -TERM -- -$$
        fi
    
        # Wait for all child processes to terminate
        wait
        echo "All subprocesses terminated. Exiting."
        exit 0
    }
    trap terminate SIGTERM SIGINT
fi

echo "Starting..."

####################
# Starting scripts #
####################

for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    echo "$SCRIPTS: executing"

    # Check if run as root
    if test "$(id -u)" == 0 && test "$(id -u)" == 0; then
        chown "$(id -u)":"$(id -g)" "$SCRIPTS"
        chmod a+x "$SCRIPTS"
    else
        bashio::log.warning "Script executed with user $(id -u):$(id -g), things can break and chown won't work"
        # Disable chown and chmod in scripts
        sed -i "s/^chown /true # chown /g" "$SCRIPTS"
        sed -i "s/ chown / true # chown /g" "$SCRIPTS"
        sed -i "s/^chmod /true # chmod /g" "$SCRIPTS"
        sed -i "s/ chmod / true # chmod /g" "$SCRIPTS"
    fi

    # Get current shebang, if not available use another
    currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$SCRIPTS")"
    if [ ! -f "${currentshebang%% *}" ]; then
        for shebang in "/command/with-contenv bashio" "/usr/bin/env bashio" "/usr/bin/bashio" "/bin/bash" "/bin/sh"; do if [ -f "${shebang%% *}" ]; then break; fi; done
        sed -i "s|$currentshebang|$shebang|g" "$SCRIPTS"
    fi

    # Use source to share env variables when requested
    if [ "${ha_entry_source:-null}" = true ] && command -v "source" &>/dev/null; then
        # Exit cannot be used with source
        sed -i "s/(.*\s|^)exit ([0-9]+)/\1 return \2 || exit \2/g" "$SCRIPTS"
        sed -i "s/bashio::exit.nok/return 1/g" "$SCRIPTS"
        sed -i "s/bashio::exit.ok/return 0/g" "$SCRIPTS"
        # shellcheck source=/dev/null
        source "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    else
        # Support for posix only shell
        "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    fi

    # Cleanup
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
