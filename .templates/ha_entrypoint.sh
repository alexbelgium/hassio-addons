#!/command/with-contenv bashio
# shellcheck shell=bash

set -e  # Exit immediately if a command exits with a non-zero status


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
    "/bin/bash"
    "/bin/sh"
)

# Find the first valid shebang interpreter in candidate list by probing bashio::addon.version
shebang=""
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for candidate in "${candidate_shebangs[@]}"; do
    echo "Trying $candidate"
    # Build a tiny probe script that prints the addon version
    printf '#!%s\n' "$candidate" >"$tmp"
    cat >>"$tmp" <<'EOF'
out="$(bashio::addon.version 2>/dev/null || true)"
[ -n "$out" ] && printf '%s\n' "$out"
EOF
    chmod +x "$tmp"

    # Run the probe and check for at least one digit in the output
    out="$(exec "$tmp" 2>/dev/null || true)"
    if printf '%s' "$out" | grep -qE '[0-9]'; then
        shebang="$candidate"
        break
    fi
done

if [ -z "$shebang" ]; then
    echo "ERROR: No valid shebang found!" >&2
    exit 1
fi

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

    # Replace the shebang in the script with the valid one
    sed -i "1s|^.*|#!$shebang|" "$SCRIPTS"

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
    shopt -s nullglob  # Don't expand unmatched globs to themselves
    for runfile in /etc/services.d/*/run /etc/s6-overlay/s6-rc.d/*/run; do
        [ -f "$runfile" ] || continue
        echo "Starting: $runfile"
        # Replace the shebang line in each runfile
        sed -i "1s|^.*|#!$shebang|" "$runfile"
        # Replace s6-setuidgid calls with 'su' (bash-based) equivalents
        sed -i -E 's|^s6-setuidgid[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \1 -c "\2"|g' "$runfile"
        chmod +x "$runfile"
        ( exec "$runfile" ) & true        
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
        if command -v pgrep &>/dev/null; then
            for pid in $(pgrep -P $$); do
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
            done
        else
            # Fallback: Scan /proc for children
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
