#!/command/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC1090

set -Eeuo pipefail

echo "Starting..."

####################
# Starting scripts #
####################

PID1=false
if [ "$$" -eq 1 ]; then
    PID1=true
fi

run_script() {
    local runfile="$1"
    local script_kind="$2"

    echo "$runfile: executing"

    # FIX: Correct current shebang parsing
    local currentshebang
    currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$runfile")"

    # IMPROVED: Fix shebang if interpreter missing
    if [ ! -f "${currentshebang%% *}" ]; then
        local shebanglist="/usr/bin/bashio /usr/bin/bash /usr/bin/sh /bin/bash /bin/sh"
        if ! "$PID1"; then
            shebanglist="/usr/bin/with-contenv bashio /command/with-contenv bashio $shebanglist"
        fi
        for shebang in $shebanglist; do
            local command_path="${shebang%% *}"
            if [ -x "$command_path" ] && "$command_path" echo "yes" > /dev/null 2>&1; then
                echo "Valid shebang: $shebang"
                sed -i "1s|.*|#!$shebang|" "$runfile"
                break
            fi
        done
    fi

    # Check if run as root
    if [ "$(id -u)" -eq 0 ]; then
        chown "$(id -u)":"$(id -g)" "$runfile"
        chmod a+x "$runfile"
    else
        if [ -t 1 ]; then
            echo -e "\e[38;5;214m$(date) WARNING: Script executed as UID $(id -u), chown/chmod may fail\e[0m"
        else
            echo "$(date) WARNING: Script executed as UID $(id -u), chown/chmod may fail"
        fi
        # Disable chown/chmod in script
        sed -i -E 's/^([[:space:]]*)chown /\1true # chown /' "$runfile"
        sed -i -E 's/^([[:space:]]*)chmod /\1true # chmod /' "$runfile"
    fi

    # Replace s6-setuidgid with su fallback if s6-setuidgid is missing
    if ! command -v s6-setuidgid >/dev/null 2>&1; then
        sed -i -E 's|s6-setuidgid[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \1 -c "\2"|g' "$runfile"
    fi

    # Execute script
    if [[ "$script_kind" == service ]]; then
        "$runfile" &
    else
        if [ "${ha_entry_source:-null}" = true ]; then
            sed -Ei 's/(^|[[:space:]])exit ([0-9]+)/\1return \2 || exit \2/g' "$runfile"
            sed -i "s/bashio::exit.nok/return 1/g" "$runfile"
            sed -i "s/bashio::exit.ok/return 0/g" "$runfile"
            source "$runfile" || echo -e "\033[0;31mError\033[0m : $runfile exiting $?"
        else
            "$runfile" || echo -e "\033[0;31mError\033[0m : $runfile exiting $?"
        fi
    fi

    # Cleanup only temporary scripts
    if [[ "$script_kind" != service && "$runfile" == /tmp/* ]]; then
        rm -f "$runfile"
    fi
}

# Loop through /etc/cont-init.d/*
for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    run_script "$SCRIPTS" script
done

# Start services.d
if [ -d /etc/services.d ]; then
    if "$PID1"; then
        for service_dir in /etc/services.d/*; do
            SCRIPTS="${service_dir}/run"
            [ -e "$SCRIPTS" ] || continue
            run_script "$SCRIPTS" service
        done
    else
        echo "Not PID 1 — skipping service startup"
    fi
fi

######################
# Starting container #
######################

if "$PID1"; then
    echo
    echo -e "\033[0;32mEverything started!\033[0m"

    terminate() {
        echo "Termination signal received, forwarding to subprocesses..."

        if command -v pgrep &> /dev/null; then
            for pid in $(pgrep -P "$$"); do
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
            done
        else
            for pid in /proc/[0-9]*/; do
                pid=${pid#/proc/}
                pid=${pid%/}
                if [[ "$pid" -ne 1 ]] && grep -q "^PPid:\s*$$" "/proc/$pid/status" 2>/dev/null; then
                    echo "Terminating child PID $pid"
                    kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
                fi
            done
        fi

        sleep 5
        kill -KILL -$$ 2>/dev/null || true
        wait
        echo "All subprocesses terminated. Exiting."
        exit 0
    }

    trap terminate SIGTERM SIGINT
    wait -n
else
    echo
    echo -e "\033[0;32mStarting the upstream container\033[0m"
    echo
    if [ -f /docker-mods ]; then exec /docker-mods; fi
fi
