#!/command/with-contenv bashio
# shellcheck shell=bash

set -e # Exit immediately if a command exits with a non-zero status

# Detect if this is PID1 (main container process) — do this once at the start
PID1=false
if [ "$$" -eq 1 ]; then
    PID1=true
    echo "Starting as entrypoint"
else
    echo "Starting custom scripts"
fi

######################
# Select the shebang #
######################

# List of candidate shebangs, prioritize with-contenv if PID1
candidate_shebangs=()
if $PID1; then
    candidate_shebangs+=("/command/with-contenv bashio" "/usr/bin/with-contenv bashio")
fi
candidate_shebangs+=(
    "/usr/bin/env bashio"
    "/usr/bin/bashio"
    "/usr/bin/bash"
    "/usr/bin/sh"
    "/bin/bash"
    "/bin/sh"
)

# Find the first valid shebang interpreter in candidate list
shebang=""
for candidate in "${candidate_shebangs[@]}"; do
    command_path="${candidate%% *}"
    # Test if command exists and can actually execute a shell command (for shells)
    if [ -x "$command_path" ]; then
        # Try as both 'sh -c' and 'bashio echo' style
        if "$command_path" -c 'echo yes' > /dev/null 2>&1 || "$command_path" echo "yes" > /dev/null 2>&1; then
            shebang="$candidate"
            break
        fi
    fi
done
if [ -z "$shebang" ]; then
    echo "ERROR: No valid shebang found!"
    exit 1
fi

####################
# Helper functions #
####################

apply_s6_mods() {
    local file="$1"
    sed -i "1s|^.*|#!$shebang|" "$file"
    #sed -i -E 's|s6-setuidgid[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \1 -c "\2"|g' "$file"
    sed -i -E 's|s6-svwait[[:space:]]+-d[[:space:]]+([^[:space:]]+)|bash -c '\''while [ -f \1/supervise/pid ]; do sleep 0.5; done'\''|g' "$file"
    sed -i -E 's|s6-setuidgid([[:space:]]+-[[:alnum:]-]+)?[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \2 -c "\3"|g' "$file"
    sed -i -E 's|s6-envuidgid([[:space:]]+-[^[:space:]]+)*[[:space:]]+([^[:space:]]+)|id -u \2 \|\| true|g' "$file"
    sed -i -E '/^[[:space:]]*s6-applyuidgid\b/d' "$file"
    chmod +x "$file" || true
}

####################
# Starting scripts #
####################

# Loop through /etc/cont-init.d/* scripts and execute them
for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    echo "$SCRIPTS: executing"

    # Check if run as root (UID 0)
    if [ "$(id -u)" -eq 0 ]; then
        # Fix permissions for root user
        chown "$(id -u)":"$(id -g)" "$SCRIPTS"
        chmod a+x "$SCRIPTS"
    else
        echo -e "\e[38;5;214m$(date) WARNING: Script executed with user $(id -u):$(id -g), things can break and chown won't work\e[0m"
        # Disable chown and chmod commands inside the script for non-root users
        sed -i "s/^\s*chown /true # chown /g" "$SCRIPTS"
        sed -i "s/^\s*chmod /true # chmod /g" "$SCRIPTS"
    fi

    # Apply s6 compatibility tweaks
    if $PID1; then
        apply_s6_mods "$SCRIPTS"
    fi

    # Optionally use 'source' to share env variables, when requested
    if [ "${ha_entry_source:-null}" = true ]; then
        # Replace exit with return, so sourced scripts can return errors
        sed -i -E 's/^\s*exit ([0-9]+)/return \1 \|\| exit \1/g' "$SCRIPTS"
        sed -i 's/bashio::exit\.nok/return 1/g' "$SCRIPTS"
        sed -i 's/bashio::exit\.ok/return 0/g' "$SCRIPTS"
        # shellcheck disable=SC1090
        source "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    else
        "$SCRIPTS" || echo -e "\033[0;31mError\033[0m : $SCRIPTS exiting $?"
    fi

    # Cleanup after execution
    rm "$SCRIPTS"
done

# Start run scripts in services.d and s6-overlay/s6-rc.d if PID1
if $PID1; then
    shopt -s nullglob # Don't expand unmatched globs to themselves
    for runfile in /etc/services.d/*/run /etc/s6-overlay/s6-rc.d/*/run; do
        [ -f "$runfile" ] || continue
        echo "Starting: $runfile"
        apply_s6_mods "$runfile"
        (exec "$runfile") &
        true
    done
    shopt -u nullglob
fi

######################
# Starting container #
######################

# If this is PID 1, keep alive and manage sigterm for clean shutdown
if $PID1; then
    echo " "
    echo -e "\033[0;32mEverything started!\033[0m"
    terminate() {
        echo "Termination signal received, forwarding to subprocesses..."
        # Terminate all direct child processes
        if command -v pgrep &> /dev/null; then
            for pid in $(pgrep -P $$); do
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2> /dev/null || echo "Failed to terminate PID $pid"
            done
        else
            # Fallback: Scan /proc for children
            for pid in /proc/[0-9]*/; do
                pid=${pid#/proc/}
                pid=${pid%/}
                if [[ "$pid" -ne 1 ]] && grep -q "^PPid:\s*$$" "/proc/$pid/status" 2> /dev/null; then
                    echo "Terminating child PID $pid"
                    kill -TERM "$pid" 2> /dev/null || echo "Failed to terminate PID $pid"
                fi
            done
        fi
        wait
        echo "All subprocesses terminated. Exiting."
        exit 0
    }
    trap terminate SIGTERM SIGINT
    # Main keep-alive loop
    while :; do
        sleep infinity &
        wait $!
    done
else
    echo " "
    echo -e "\033[0;32mStarting the upstream container\033[0m"
    echo " "
    # Launch optional mods script if present
    if [ -f /docker-mods ]; then exec /docker-mods; fi
fi
