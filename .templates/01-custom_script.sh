#!/bin/bash
# shellcheck shell=bash
set -e

##########################################
# Pick an exec-capable directory         #
##########################################

pick_exec_dir() {
  local d
  for d in /dev/shm /run /var/run /mnt /root /; do
    if [ -d "$d" ] && [ -w "$d" ]; then
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
  echo "ERROR: Could not find an exec-capable writable directory."
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
  if [ -f /usr/local/lib/bashio-standalone.sh ]; then
    . /usr/local/lib/bashio-standalone.sh
    _bv="$(bashio::addon.version)"
  fi
fi

echo "$_bv"
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
  echo "ERROR: No valid shebang found." >&2
  printf ' - %s\n' "${candidate_shebangs[@]}" >&2
  if [ "${#SHEBANG_ERRORS[@]}" -gt 0 ]; then
    printf '%s\n' "${SHEBANG_ERRORS[@]}" >&2
  fi
  exit 1
fi

sed -i "1s|^.*|#!$shebang|" "$0"

if ! command -v bashio::addon.version >/dev/null 2>&1; then
  for f in /usr/lib/bashio/bashio.sh /usr/lib/bashio/lib.sh /usr/src/bashio/bashio.sh /usr/local/lib/bashio/bashio.sh /usr/local/lib/bashio-standalone.sh; do
    if [ -f "$f" ]; then
      # shellcheck disable=SC1090
      . "$f"
      break
    fi
  done
fi

##################
# INITIALIZATION #
##################

# Exit if /config is not mounted or HA not used
if [ ! -d /config ] || ! bashio::supervisor.ping 2> /dev/null; then
    echo "..."
    exit 0
fi

# Define slug
slug="${HOSTNAME/-/_}"
slug="${slug#*_}"

# Check type of config folder
if [ ! -f /config/configuration.yaml ] && [ ! -f /config/configuration.json ]; then
    # New config location
    CONFIGLOCATION="/config"
    CONFIGFILEBROWSER="/addon_configs/${HOSTNAME/-/_}/$slug.sh"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_autoscripts"
    CONFIGFILEBROWSER="/homeassistant/addons_autoscripts/$slug.sh"
fi

# Default location
mkdir -p "$CONFIGLOCATION" || true
CONFIGSOURCE="$CONFIGLOCATION/$slug.sh"

bashio::log.notice "This script is used to run custom commands at start of the addon. Instructions here : https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons"
bashio::log.green "Execute $CONFIGFILEBROWSER if existing"

# Download template if no script found and exit
if [ ! -f "$CONFIGSOURCE" ]; then
    TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/script.template"
    curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGSOURCE" || true
    exit 0
fi

# Convert scripts to linux
dos2unix "$CONFIGSOURCE" &> /dev/null || true
chmod +x "$CONFIGSOURCE"

sed -i "1s|^.*|#!$shebang|" "$CONFIGSOURCE"

# Check if there is actual commands
while IFS= read -r line; do
    # Remove leading and trailing whitespaces
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Check if line is not empty and does not start with #
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        bashio::log.green "... script found, executing"
        /."$CONFIGSOURCE"
        break
    fi
done < "$CONFIGSOURCE"
