#!/command/with-contenv bashio
# shellcheck shell=bash

echo "Starting..."

####################
# Starting scripts #
####################

for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    echo "$SCRIPTS: executing"

    # Check if run as root
    if [ "$(id -u)" -eq 0 ]; then
        chown "$(id -u)":"$(id -g)" "$SCRIPTS"
        chmod a+x "$SCRIPTS"
    else
        echo -e "\e[38;5;214m$(date) WARNING: Script executed with user $(id -u):$(id -g), things can break and chown won't work\e[0m"
        # Disable chown and chmod in scripts
        sed -i "s/^chown /true # chown /g" "$SCRIPTS"
        sed -i "s/ chown / true # chown /g" "$SCRIPTS"
        sed -i "s/^chmod /true # chmod /g" "$SCRIPTS"
        sed -i "s/ chmod / true # chmod /g" "$SCRIPTS"
    fi

    # Get current shebang, if not available use another
    currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$SCRIPTS")"
    if [ ! -f "${currentshebang%% *}" ]; then
        for shebang in "/command/with-contenv bashio" "/usr/bin/env bashio" "/usr/bin/bashio" "/bin/bash" "/bin/sh"; do 
            if [ -f "${shebang%% *}" ] && [[ "${shebang%% *} echo \"yes\"" ]]; then
                break
            fi
        done
        sed -i "s|$currentshebang|$shebang|g" "$SCRIPTS"
    fi

    # Use source to share env variables when requested
    if [ "${ha_entry_source:-null}" = true ] && command -v "source" &>/dev/null; then
        sed -i "s/(.*\s|^)exit ([0-9]+)/\1 return \2 || exit \2/g" "$SCRIPTS"
        sed -i "s/bashio::exit.nok/return 1/g" "$SCRIPTS"
        sed -i "s/bashio::exit.ok/return 0/g" "$SCRIPTS"
        source "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    else
        "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    fi

    # Cleanup
    rm "$SCRIPTS"

done

######################
# Starting container #
######################

# If PID 1, keep alive and manage sigterm
if [ "$$" -eq 1 ]; then
    echo " "
    echo -e "\033[0;32mEverything started!\033[0m"
    terminate() {
        echo "Termination signal received, forwarding to subprocesses..."
        # Terminate all subprocesses
        if command -v pgrep &>/dev/null; then
            for pid in $(pgrep -P $$); do
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
            done
        else
            # Fallback to iterating through /proc if pgrep is not available
            for pid in /proc/[0-9]*/; do
                pid=${pid#/proc/}
                pid=${pid%/}
                if [[ "$pid" -ne 1 ]] && grep -q "^PPid:\s*$$" "/proc/$pid/status" 2>/dev/null; then
                    echo "Terminating child PID $pid"
                    kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
                fi
            done
        fi
        
        wait
        echo "All subprocesses terminated. Exiting."
        exit 0
    }
    trap terminate SIGTERM SIGINT
    while :; do sleep infinity & wait $!; done
else
    echo " "
    echo -e "\033[0;32mStarting the upstream container\033[0m"
    echo " "
    # Launch lsio mods
    if [ -f /docker-mods ]; then exec /docker-mods; fi
fi
