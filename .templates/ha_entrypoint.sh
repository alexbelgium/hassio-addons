#!/command/with-contenv bashio
# shellcheck shell=bash

echo "Starting..."

####################
# Starting scripts #
####################

run_script() {
    runfile="$1"
    script_kind="$2"
    echo "$runfile: executing"
    # Check if run as root
    if [ "$(id -u)" -eq 0 ]; then
        chown "$(id -u)":"$(id -g)" "$runfile"
        chmod a+x "$runfile"
    else
        echo -e "\e[38;5;214m$(date) WARNING: Script executed with user $(id -u):$(id -g), things can break and chown won't work\e[0m"
        # Disable chown and chmod in scripts
        sed -i -E 's/^([[:space:]]*)chown /\1true # chown /' "$runfile"
        sed -i -E 's/^([[:space:]]*)chmod /\1true # chmod /' "$runfile"
    fi

    # Replace s6-setuidgid with su-based equivalent
    if ! command -v s6-setuidgid > /dev/null 2>&1; then
        sed -i -E 's|s6-setuidgid[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \1 -c "\2"|g' "$runfile"
    fi

    # Get current shebang, if not available use another
    currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$SCRIPTS")"
    if [ ! -f "${currentshebang%% *}" ]; then
        for shebang in "/command/with-contenv bashio" "/usr/bin/with-contenv bashio" "/usr/bin/env bashio" "/usr/bin/bashio" "/usr/bin/bash" "/usr/bin/sh" "/bin/bash" "/bin/sh"; do
            command_path="${shebang%% *}"
            if [ -x "$command_path" ] && "$command_path" echo "yes" > /dev/null 2>&1; then
                echo "Valid shebang: $shebang"
                break
            fi
        done
        sed -i "s|$currentshebang|$shebang|g" "$SCRIPTS"
    fi

    # Use source to share env variables when requested
    if [[ "$script_kind" == service ]]; then
        (exec "$runfile") &
        true
    else
        if [ "${ha_entry_source:-null}" = true ]; then
            sed -Ei 's/(^|[[:space:]])exit ([0-9]+)/\1return \2 || exit \2/g' "$runfile"
            sed -i "s/bashio::exit.nok/return 1/g" "$runfile"
            sed -i "s/bashio::exit.ok/return 0/g" "$runfile"
            # shellcheck disable=SC1090
            source "$runfile" || echo -e "\033[0;31mError\033[0m : $runfile exiting $?"
        else
            "$runfile" || echo -e "\033[0;31mError\033[0m : $runfile exiting $?"
        fi
    fi

    # Cleanup
    if [[ "$script_kind" != service ]]; then
        rm "$runfile"
    fi
}

# Loop through /etc/cont-init.d/*
for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    run_script "$SCRIPTS" script
done

# Start services.d
if [ "$$" -eq 1 ]; then
    for service_dir in /etc/services.d/*; do
        SCRIPTS="${service_dir}/run"
        [ -e "$SCRIPTS" ] || continue
        run_script "$SCRIPTS" service
    done
else
    echo "Not PID 1 — skipping service startup"
fi

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
        if command -v pgrep &> /dev/null; then
            for pid in $(pgrep -P $$); do
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2> /dev/null || echo "Failed to terminate PID $pid"
            done
        else
            # Fallback to iterating through /proc if pgrep is not available
            for pid in /proc/[0-9]*/; do
                pid=${pid#/proc/}
                pid=${pid%/}
                if [[ "$pid" -ne 1 ]] && grep -q "^PPid:\s*$$" "/proc/$pid/status" 2> /dev/null; then
                    echo "Terminating child PID $pid"
                    kill -TERM "$pid" 2> /dev/null || echo "Failed to terminate PID $pid"
                fi
            done
        fi
        kill -TERM -$$ 2> /dev/null || true
        sleep 5
        kill -KILL -$$ 2> /dev/null || true

        wait
        echo "All subprocesses terminated. Exiting."
        exit 0
    }
    trap terminate SIGTERM SIGINT
    wait -n
else
    echo " "
    echo -e "\033[0;32mStarting the upstream container\033[0m"
    echo " "
    # Launch lsio mods
    if [ -f /docker-mods ]; then exec /docker-mods; fi
fi
