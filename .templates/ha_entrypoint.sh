#!/command/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC1090

set -Eeuo pipefail

echo "Starting..."

####################
# Global Variables #
####################

PID1=false
if [ "$$" -eq 1 ]; then
    PID1=true
fi

# Cache command availability at startup
readonly HAS_S6_SETUIDGID=$(command -v s6-setuidgid > /dev/null 2>&1 && echo true || echo false)
readonly HAS_PGREP=$(command -v pgrep > /dev/null 2>&1 && echo true || echo false)
readonly HAS_PS=$(command -v ps > /dev/null 2>&1 && echo true || echo false)
readonly IS_ROOT=$([ "$(id -u)" -eq 0 ] && echo true || echo false)
readonly IS_TTY=$([ -t 1 ] && echo true || echo false)

# Available interpreters array (populated by function)
AVAILABLE_INTERPRETERS=()

####################
# Helper Functions #
####################

log_warning() {
    local message="$1"
    if "$IS_TTY"; then
        echo -e "\e[38;5;214m$(date) WARNING: $message\e[0m"
    else
        echo "$(date) WARNING: $message"
    fi
}

log_error() {
    local message="$1"
    echo -e "\033[0;31mError\033[0m : $message" >&2
}

build_available_interpreters() {
    AVAILABLE_INTERPRETERS=()
    local shebang_list="/usr/bin/bashio /usr/bin/bash /usr/bin/sh /bin/bash /bin/sh"
    local shebang command_path
    
    if ! "$PID1"; then
        shebang_list="/usr/bin/with-contenv bashio /command/with-contenv bashio $shebang_list"
    fi
    
    for shebang in $shebang_list; do
        command_path="${shebang%% *}"
        if [ -x "$command_path" ] && "$command_path" echo "yes" > /dev/null 2>&1; then
            AVAILABLE_INTERPRETERS+=("$shebang")
        fi
    done
}

is_valid_shebang_line() {
    local line="$1"
    # Check if line starts with #! and has content after it
    [[ "$line" =~ ^#![[:space:]]*[^[:space:]]+ ]]
}

fix_shebang() {
    local runfile="$1"
    
    # Get first line to check if it's a shebang
    local first_line
    first_line="$(sed -n '1p' "$runfile")"
    
    # If it's not a shebang line, don't modify
    if ! is_valid_shebang_line "$first_line"; then
        log_warning "$runfile: No valid shebang found, skipping shebang fix"
        return 0
    fi
    
    # Extract current interpreter path
    local currentshebang
    currentshebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$runfile")"
    local interpreter_path="${currentshebang%% *}"
    
    # Check if current interpreter exists and is executable
    if [ -x "$interpreter_path" ]; then
        return 0
    fi
    
    # Find first available interpreter
    if [ ${#AVAILABLE_INTERPRETERS[@]} -gt 0 ]; then
        local new_shebang="${AVAILABLE_INTERPRETERS[0]}"
        echo "Fixing shebang in $runfile: $new_shebang"
        sed -i "1s|^#!.*|#!$new_shebang|" "$runfile"
        return 0
    fi
    
    log_error "No valid interpreter found for $runfile"
    return 1
}

validate_script_syntax() {
    local runfile="$1"
    
    # Extract shebang to determine interpreter
    local shebang
    shebang="$(sed -n '1{s/^#![[:blank:]]*//p;q}' "$runfile")"
    local interpreter="${shebang%% *}"
    
    # Only validate bash/sh scripts
    case "$interpreter" in
        */bash|*/sh|bash|sh)
            if ! "$interpreter" -n "$runfile" 2>/dev/null; then
                log_error "$runfile: Syntax validation failed"
                return 1
            fi
            ;;
    esac
    return 0
}

apply_script_modifications() {
    local runfile="$1"
    local sed_commands=()
    
    # Build sed command array based on conditions
    if ! "$IS_ROOT"; then
        sed_commands+=(
            '-E' '-e' 's/^([[:space:]]*)chown /\1true # chown /'
            '-E' '-e' 's/^([[:space:]]*)chmod /\1true # chmod /'
        )
    fi
    
    if ! "$HAS_S6_SETUIDGID"; then
        sed_commands+=(
            '-E' '-e' 's|s6-setuidgid[[:space:]]+([a-zA-Z0-9._-]+)[[:space:]]+(.*)$|su -s /bin/bash \1 -c "\2"|g'
        )
    fi
    
    if [ "${ha_entry_source:-null}" = true ]; then
        sed_commands+=(
            '-E' '-e' 's/(^|[[:space:]])exit ([0-9]+)/\1return \2 || exit \2/g'
            '-E' '-e' 's/bashio::exit\.nok/return 1/g'
            '-E' '-e' 's/bashio::exit\.ok/return 0/g'
        )
    fi
    
    # Apply all modifications in a single sed call if any are needed
    if [ ${#sed_commands[@]} -gt 0 ]; then
        sed -i "${sed_commands[@]}" "$runfile"
    fi
}

set_permissions() {
    local runfile="$1"
    
    if "$IS_ROOT"; then
        chown "$(id -u)":"$(id -g)" "$runfile"
        chmod a+x "$runfile"
    else
        log_warning "Script executed as UID $(id -u), chown/chmod may fail for $runfile"
        # Try to make executable anyway
        chmod +x "$runfile" 2>/dev/null || true
    fi
}

####################
# Main Functions   #
####################

run_script() {
    local runfile="$1"
    local script_kind="$2"

    echo "$runfile: executing"

    # Fix shebang if needed
    if ! fix_shebang "$runfile"; then
        log_error "$runfile: Cannot fix shebang, skipping"
        return 1
    fi
    
    # Validate script syntax
    if ! validate_script_syntax "$runfile"; then
        log_error "$runfile: Syntax validation failed, skipping"
        return 1
    fi
    
    # Set permissions
    set_permissions "$runfile"
    
    # Apply script modifications
    apply_script_modifications "$runfile"

    # Execute script
    case "$script_kind" in
        service)
            "$runfile" &
            ;;
        script)
            if [ "${ha_entry_source:-null}" = true ]; then
                # Additional safety check before sourcing
                if validate_script_syntax "$runfile"; then
                    if source "$runfile" || log_error "$runfile exiting $?"; then
                        rm "$runfile"
                    fi
                else
                    log_error "$runfile: Failed syntax check before sourcing"
                    return 1
                fi
            else
                "$runfile" || log_error "$runfile exiting $?"
            fi
            ;;
    esac

    # Cleanup temporary scripts
    if [[ "$script_kind" != service && "$runfile" == /tmp/* ]]; then
        rm -f "$runfile"
    fi
}

terminate_children() {
    echo "Termination signal received, forwarding to subprocesses..."

    if "$HAS_PGREP"; then
        # Use pgrep for efficient child process discovery
        local child_pids
        child_pids=$(pgrep -P "$$" 2>/dev/null || true)
        if [ -n "$child_pids" ]; then
            echo "$child_pids" | while IFS= read -r pid; do
                [ -n "$pid" ] || continue
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
            done
        fi
    elif "$HAS_PS"; then
        # Fallback to ps
        local child_pids
        child_pids=$(ps -o pid= --ppid="$$" 2>/dev/null | tr -d ' ' || true)
        if [ -n "$child_pids" ]; then
            echo "$child_pids" | while IFS= read -r pid; do
                [ -n "$pid" ] || continue
                echo "Terminating child PID $pid"
                kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
            done
        fi
    else
        # Last resort: proc filesystem parsing (optimized)
        for pid_dir in /proc/[0-9]*; do
            [ -d "$pid_dir" ] || continue
            local pid="${pid_dir#/proc/}"
            
            # Skip self and init
            [ "$pid" != "$$" ] && [ "$pid" != "1" ] || continue
            
            # Check if it's our child using stat file (more efficient)
            if [ -r "$pid_dir/stat" ]; then
                local ppid
                ppid=$(awk '{print $4}' "$pid_dir/stat" 2>/dev/null || true)
                if [ "$ppid" = "$$" ]; then
                    echo "Terminating child PID $pid"
                    kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
                fi
            fi
        done
    fi

    # Wait for graceful termination
    sleep 5
    
    # WARNING: This kills the entire process group - only safe in PID1 context
    if "$PID1"; then
        kill -KILL -$$ 2>/dev/null || true
    fi
    
    wait
    echo "All subprocesses terminated. Exiting."
    exit 0
}

####################
# Initialization   #
####################

# Build available interpreters list
build_available_interpreters

####################
# Starting scripts #
####################

# Process initialization scripts
if [ -d /etc/cont-init.d ]; then
    for script_file in /etc/cont-init.d/*; do
        [ -e "$script_file" ] || continue
        run_script "$script_file" script
    done
fi

# Start services if we're PID 1
if [ -d /etc/services.d ]; then
    if "$PID1"; then
        for service_dir in /etc/services.d/*; do
            [ -d "$service_dir" ] || continue
            local service_script="${service_dir}/run"
            [ -e "$service_script" ] || continue
            run_script "$service_script" service
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

    trap terminate_children SIGTERM SIGINT
    wait -n
else
    echo
    echo -e "\033[0;32mStarting the upstream container\033[0m"
    echo
    if [ -f /docker-mods ]; then 
        exec /docker-mods
    fi
fi
