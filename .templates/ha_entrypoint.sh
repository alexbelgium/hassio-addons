#!/bin/bash
# shellcheck shell=bash
set -euo pipefail

######################################
# Accept running without supervisor  #
######################################

if ! bashio::supervisor.ping 2> /dev/null; then
    bashio::log.warning "Using standalone mode to run bashio commands without HA supervisor"
    mv /usr/local/lib/bashio-standalone.sh /usr/bin/bashio
    chmod +x /usr/bin/bashio
fi

##########################################
# Detect if this is PID1 (main process)  #
##########################################

PID1=false
if [ "$$" -eq 1 ]; then
  PID1=true
  echo "Starting as entrypoint"
  if [ -d /command ]; then
    ln -sf /command/* /usr/bin/ 2>/dev/null || true
  fi
else
  echo "Starting custom scripts"
fi

##########################################
# Pick an exec-capable directory         #
##########################################

pick_exec_dir() {
  # Prefer locations that are commonly exec-capable in containers
  # and writable. Avoid /tmp because it may be mounted noexec.
  local d
  for d in /dev/shm /run /var/run /mnt /root /; do
    if [ -d "$d" ] && [ -w "$d" ]; then
      # Create a tiny test executable to confirm "exec" works
      local t="${d%/}/.exec_test_$$"
      printf '#!/bin/sh\necho ok\n' > "$t" 2>/dev/null || { rm -f "$t" 2>/dev/null || true; continue; }
      chmod 700 "$t" 2>/dev/null || { rm -f "$t" 2>/dev/null || true; continue; }
      if "$t" >/dev/null 2>&1; then
        rm -f "$t" 2>/dev/null || true
        echo "$d"
        return 0
      fi
      rm -f "$t" 2>/dev/null || true
    fi
  done
  return 1
}

EXEC_DIR="$(pick_exec_dir || true)"
if [ -z "${EXEC_DIR:-}" ]; then
  echo "ERROR: Could not find an exec-capable writable directory (e.g., /dev/shm,/run)."
  echo "Your environment likely mounts all writable dirs as noexec; shebang validation cannot run safely."
  exit 1
fi

######################
# Select the shebang #
######################

candidate_shebangs=(
  "/command/with-contenv bashio"
  "/usr/bin/with-contenv bashio"
  "/usr/bin/env bashio"
  "/usr/bin/bashio"
  "/usr/bin/bash"
  "/bin/bash"
  "/usr/bin/sh"
  "/bin/sh"
)

probe_script_content='
set -e

if ! command -v bashio::addon.version >/dev/null 2>&1; then
  for f in \
    /usr/lib/bashio/bashio.sh \
    /usr/lib/bashio/lib.sh \
    /usr/src/bashio/bashio.sh \
    /usr/local/lib/bashio/bashio.sh
  do
    if [ -f "$f" ]; then
      # shellcheck disable=SC1090
      . "$f"
      break
    fi
  done
fi

bashio::addon.version
'

validate_shebang() {
  local candidate="$1"
  local tmp out rc

  # shellcheck disable=SC2206
  local cmd=( $candidate )
  local exe="${cmd[0]}"

  if [ ! -x "$exe" ]; then
    echo " - FAIL (not executable): #!$candidate" >&2
    return 1
  fi

  tmp="${EXEC_DIR%/}/shebang_test.$$.$RANDOM"
  {
    printf '#!%s\n' "$candidate"
    printf '%s\n' "$probe_script_content"
  } > "$tmp"
  chmod 700 "$tmp" 2>/dev/null || true

  set +e
  out="$("$tmp" 2>"${EXEC_DIR%/}/shebang_probe_err.$$")"
  rc=$?
  set -e

  rm -f "$tmp" 2>/dev/null || true

  if [ "$rc" -eq 0 ] && [ -n "${out:-}" ] && [ "$out" != "null" ]; then
    rm -f "${EXEC_DIR%/}/shebang_probe_err.$$" 2>/dev/null || true
    return 0
  fi

  {
    echo " - FAIL: #!$candidate"
    echo "   rc=$rc, stdout='${out:-}'"
    if [ -s "${EXEC_DIR%/}/shebang_probe_err.$$" ]; then
      echo "   stderr:"
      sed -n '1,8p' "${EXEC_DIR%/}/shebang_probe_err.$$"
    else
      echo "   stderr: <empty>"
    fi
  } >&2
  rm -f "${EXEC_DIR%/}/shebang_probe_err.$$" 2>/dev/null || true
  return 1
}

shebang=""
for candidate in "${candidate_shebangs[@]}"; do
  if validate_shebang "$candidate"; then
    shebang="$candidate"
    break
  fi
done

if [ -z "$shebang" ]; then
  echo "ERROR: No valid shebang found (unable to execute bashio::addon.version via candidates)." >&2
  echo "Tried:" >&2
  printf ' - %s\n' "${candidate_shebangs[@]}" >&2
  exit 1
fi

echo "Selected shebang: #!$shebang"

####################
# Starting scripts #
####################

run_one_script() {
  local script="$1"

  echo "$script: executing"

  if [ "$(id -u)" -eq 0 ]; then
    chown "$(id -u)":"$(id -g)" "$script" || true
    chmod a+x "$script" || true
  else
    echo -e "\e[38;5;214m$(date) WARNING: Script executed with user $(id -u):$(id -g), things can break and chown won't work\e[0m"
    sed -i "s/^[[:space:]]*chown /true # chown /g" "$script"
    sed -i "s/^[[:space:]]*chmod /true # chmod /g" "$script"
  fi

  sed -i "1s|^.*|#!$shebang|" "$script"
  chmod +x "$script"

  if [ "${ha_entry_source:-null}" = "true" ]; then
    sed -i -E 's/^[[:space:]]*exit ([0-9]+)/return \1 \|\| exit \1/g' "$script"
    sed -i 's/bashio::exit\.nok/return 1/g' "$script"
    sed -i 's/bashio::exit\.ok/return 0/g' "$script"
    # shellcheck disable=SC1090
    source "$script" || echo -e "\033[0;31mError\033[0m : $script exiting $?"
  else
    "$script" || echo -e "\033[0;31mError\033[0m : $script exiting $?"
  fi

  sed -i '1a exit 0' "$script"
}

if [ -d /etc/cont-init.d ]; then
  for SCRIPTS in /etc/cont-init.d/*; do
    [ -e "$SCRIPTS" ] || continue
    run_one_script "$SCRIPTS"
  done
fi

if $PID1; then
  shopt -s nullglob
  for runfile in /etc/services.d/*/run /etc/s6-overlay/s6-rc.d/*/run; do
    [ -f "$runfile" ] || continue
    echo "Starting: $runfile"
    sed -i "1s|^.*|#!$shebang|" "$runfile"
    chmod +x "$runfile"
    (exec "$runfile") &
    true
  done
  shopt -u nullglob
fi

######################
# Starting container #
######################

if $PID1; then
  echo " "
  echo -e "\033[0;32mEverything started!\033[0m"

  terminate() {
    echo "Termination signal received, forwarding to subprocesses..."
    if command -v pgrep >/dev/null 2>&1; then
      while read -r pid; do
        [ -n "$pid" ] || continue
        echo "Terminating child PID $pid"
        kill -TERM "$pid" 2>/dev/null || echo "Failed to terminate PID $pid"
      done < <(pgrep -P "$$" || true)
    else
      for p in /proc/[0-9]*/; do
        local_pid="${p#/proc/}"
        local_pid="${local_pid%/}"
        if [ "$local_pid" -ne 1 ] && grep -q "^PPid:[[:space:]]*$$" "/proc/$local_pid/status" 2>/dev/null; then
          echo "Terminating child PID $local_pid"
          kill -TERM "$local_pid" 2>/dev/null || echo "Failed to terminate PID $local_pid"
        fi
      done
    fi
    wait || true
    echo "All subprocesses terminated. Exiting."
    exit 0
  }

  trap terminate SIGTERM SIGINT
  while :; do
    sleep infinity &
    wait $!
  done
else
  echo " "
  echo -e "\033[0;32mStarting the upstream container\033[0m"
  echo " "
  if [ -f /docker-mods ]; then
    exec /docker-mods
  fi
fi
