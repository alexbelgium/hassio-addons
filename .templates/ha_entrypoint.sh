#!/bin/bash
# shellcheck shell=bash

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
      printf '#!/bin/sh\necho ok\n' >"$t" 2>/dev/null || { rm -f "$t" 2>/dev/null || true; continue; }
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

SHEBANG_ERRORS=()

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

# Try regular bashio, fallback to standalone if unavailable or fails
set +e
_bv="$(bashio::addon.version 2>/dev/null)"
_rc=$?
set -e

if [ "$_rc" -ne 0 ] || [ -z "$_bv" ] || [ "$_bv" = "null" ]; then
  for _sf in /usr/local/lib/bashio-standalone.sh /.bashio-standalone.sh; do
    if [ -f "$_sf" ]; then
      # shellcheck disable=SC1090
      . "$_sf"
      _bv="$(bashio::addon.version 2>/dev/null || true)"
      break
    fi
  done
fi

echo "${_bv:-PROBE_OK}"
'

validate_shebang() {
  local candidate="$1"
  local tmp out rc
  local errfile msg

  # shellcheck disable=SC2206
  local cmd=( $candidate )
  local exe="${cmd[0]}"

  if [ ! -x "$exe" ]; then
    SHEBANG_ERRORS+=(" - FAIL (not executable): #!$candidate")
    return 1
  fi

  tmp="${EXEC_DIR%/}/shebang_test.$$.$RANDOM"
  errfile="${EXEC_DIR%/}/shebang_probe_err.$$"
  {
    printf '#!%s\n' "$candidate"
    printf '%s\n' "$probe_script_content"
  } >"$tmp"
  chmod 700 "$tmp" 2>/dev/null || true

  set +e
  out="$("$tmp" 2>"$errfile")"
  rc=$?
  set -e

  rm -f "$tmp" 2>/dev/null || true

  if [ "$rc" -eq 0 ] && [ -n "${out:-}" ] && [ "$out" != "null" ]; then
    rm -f "$errfile" 2>/dev/null || true
    return 0
  fi

  msg=$' - FAIL: #!'"$candidate"$'\n'"   rc=$rc, stdout='${out:-}'"$'\n'
  if [ -s "$errfile" ]; then
    msg+=$'   stderr:\n'
    msg+="$(sed -n '1,8p' "$errfile")"$'\n'
  else
    msg+=$'   stderr: <empty>\n'
  fi
  SHEBANG_ERRORS+=("$msg")
  rm -f "$errfile" 2>/dev/null || true
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
  if [ "${#SHEBANG_ERRORS[@]}" -gt 0 ]; then
    echo "Probe failures:" >&2
    printf '%s\n' "${SHEBANG_ERRORS[@]}" >&2
  fi
  exit 1
fi

####################################
# Bashio library for source fallback
####################################

BASHIO_LIB=""
for f in /usr/lib/bashio/bashio.sh /usr/lib/bashio/lib.sh /usr/src/bashio/bashio.sh /usr/local/lib/bashio/bashio.sh; do
  if [ -f "$f" ]; then
    BASHIO_LIB="$f"
    break
  fi
done
if [ -z "$BASHIO_LIB" ]; then
  for f in /usr/local/lib/bashio-standalone.sh /.bashio-standalone.sh; do
    if [ -f "$f" ]; then
      BASHIO_LIB="$f"
      break
    fi
  done
fi

##############################
# Wait for the Supervisor API #
##############################

# Many cont-init scripts build their nginx ingress config out of bashio::addon.ip_address and
# bashio::addon.ingress_port. Both come from one GET /addons/self/info, and when that is answered
# before the Supervisor is ready bashio prints nothing: the add-on then either writes
# "listen : default_server;" -- which nginx rejects with `invalid port in ":"` -- or aborts under
# set -e and leaves the %%port%% placeholders in place. Either way the add-on cannot serve ingress.
# Wait here, once, until the call returns usable values, rather than making 48 add-ons defend
# themselves against the same empty answer.
#
# Bounded and never fatal: an add-on with no SUPERVISOR_TOKEN, or a Supervisor that stays
# unreachable, still has to start. HA_SUPERVISOR_WAIT (seconds, default 30) sets the ceiling; 0
# skips the wait. When the Supervisor is already up -- the normal case -- this costs one request.

wait_for_supervisor() {
  local max="${HA_SUPERVISOR_WAIT:-30}"
  local body fields ip ingress port started deadline remaining timeout announced=0

  # Nothing to wait for without a token, and bashio could not read the values either.
  [ -n "${SUPERVISOR_TOKEN:-}" ] || return 0
  # Digits only, then forced to base 10: `test -gt` accepts a zero-padded override like 08, but
  # arithmetic expansion reads it as octal and fails, which would leave the deadline empty and
  # spin the loop below forever.
  case "$max" in '' | *[!0-9]*) return 0 ;; esac
  max=$((10#$max))
  [ "$max" -gt 0 ] || return 0
  command -v curl >/dev/null 2>&1 || return 0

  # A real wall-clock ceiling. Counting attempts would not be one: each curl can itself burn
  # --max-time before the sleep even starts.
  started=$SECONDS
  deadline=$((started + max))

  while :; do
    remaining=$((deadline - SECONDS))
    if [ "$remaining" -le 0 ]; then
      echo -e "\e[38;5;214m$(date) WARNING: Supervisor API did not report this add-on's network details within ${max}s, continuing anyway\e[0m"
      return 0
    fi

    # Never let a single request outlive the ceiling it is bounded by.
    timeout=5
    [ "$remaining" -lt "$timeout" ] && timeout="$remaining"

    body="$(curl -fsSL --connect-timeout 2 --max-time "$timeout" \
      -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
      "http://supervisor/addons/self/info" 2>/dev/null || true)"

    # Pull the three fields without depending on jq, which not every base image has. Splitting on
    # the structural characters first puts each scalar on its own line, so the key can be anchored
    # at the start of it: a string value that happens to contain the text "ip_address" cannot then
    # be mistaken for the field itself, and the result does not depend on field ordering. Handles
    # both the compact JSON the Supervisor returns and pretty-printed variants.
    fields="$(printf '%s' "$body" | sed 's/[,{}]/\n/g')"
    ip="$(printf '%s\n' "$fields" | sed -n 's/^[[:space:]]*"ip_address"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
    ingress="$(printf '%s\n' "$fields" | sed -n 's/^[[:space:]]*"ingress"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p' | head -n 1)"
    port="$(printf '%s\n' "$fields" | sed -n 's/^[[:space:]]*"ingress_port"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1)"

    # An ingress add-on also needs a usable port; a non-ingress one never gets one, so requiring
    # it there would burn the whole timeout on every boot.
    if [ -n "$ip" ] && { [ "$ingress" != "true" ] || { [ -n "$port" ] && [ "$port" != "0" ]; }; }; then
      [ "$announced" -eq 0 ] || echo "Supervisor API ready after $((SECONDS - started))s"
      return 0
    fi

    if [ "$announced" -eq 0 ]; then
      echo "Waiting for the Supervisor API to report this add-on's network details..."
      announced=1
    fi

    # Skipped when the request already consumed what was left, so the sleep cannot overshoot.
    [ "$((deadline - SECONDS))" -gt 0 ] && sleep 1
  done
}

wait_for_supervisor

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
    _run_rc=0
    "$script" || _run_rc=$?
    if [ "$_run_rc" -eq 126 ] && [ -n "${BASHIO_LIB:-}" ]; then
      echo "Direct exec failed (rc=126, likely E2BIG), retrying via source in subshell..."
      _run_rc=0
      (
        # shellcheck disable=SC1090
        . "$BASHIO_LIB" 2>/dev/null || true
        # shellcheck disable=SC1090
        . "$script"
      ) || _run_rc=$?
      if [ "$_run_rc" -ne 0 ]; then
        echo -e "\033[0;31mError\033[0m : $script exiting $_run_rc"
      fi
    elif [ "$_run_rc" -ne 0 ]; then
      echo -e "\033[0;31mError\033[0m : $script exiting $_run_rc"
    fi
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
    (
      restart_count=0
      max_restarts=5
      while true; do
        _svc_rc=0
        "$runfile" || _svc_rc=$?
        if [ "$_svc_rc" -eq 126 ] && [ -n "${BASHIO_LIB:-}" ]; then
          echo "Direct exec of $runfile failed (rc=126, likely E2BIG), retrying via source..."
          _svc_rc=0
          (
            # shellcheck disable=SC1090
            . "$BASHIO_LIB" 2>/dev/null || true
            # shellcheck disable=SC1090
            . "$runfile"
          ) || _svc_rc=$?
        fi
        rc=$_svc_rc
        if [ "$rc" -eq 0 ]; then
          echo "$runfile exited cleanly (exit 0), not restarting."
          break
        fi
        restart_count=$((restart_count + 1))
        if [ "$restart_count" -ge "$max_restarts" ]; then
          echo -e "\033[0;31mERROR: $runfile has crashed $restart_count times (last exit code: $rc), giving up.\033[0m"
          break
        fi
        echo -e "\e[38;5;214m$(date) WARNING: $runfile exited (code $rc), restarting (#${restart_count}/${max_restarts}) in 5s...\e[0m"
        sleep 5
      done
    ) &
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
    local local_pid
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
