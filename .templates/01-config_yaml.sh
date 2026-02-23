#!/bin/bash
# shellcheck shell=bash

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

bashio::addon.version
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
  for f in /usr/lib/bashio/bashio.sh /usr/lib/bashio/lib.sh /usr/src/bashio/bashio.sh /usr/local/lib/bashio/bashio.sh; do
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

# Disable if config not present
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
    CONFIGFILEBROWSER="/addon_configs/${HOSTNAME/-/_}/config.yaml"
else
    # Legacy config location
    CONFIGLOCATION="/config/addons_config/${slug}"
    CONFIGFILEBROWSER="/homeassistant/addons_config/$slug/config.yaml"
fi

# Default location
mkdir -p "$CONFIGLOCATION" || true
CONFIGSOURCE="$CONFIGLOCATION"/config.yaml

# Is there a custom path
if bashio::config.has_value 'CONFIG_LOCATION'; then
    CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
    if [[ "$CONFIGSOURCE" == *"."* ]]; then
        CONFIGSOURCE=$(dirname "$CONFIGSOURCE")
    fi
    # If does not end by config.yaml, remove trailing slash and add config.yaml
    if [[ "$CONFIGSOURCE" != *".yaml" ]]; then
        CONFIGSOURCE="${CONFIGSOURCE%/}"/config.yaml
    fi
    # Check if config is located in an acceptable location
    LOCATIONOK=""
    for location in "/share" "/config" "/data"; do
        if [[ "$CONFIGSOURCE" == "$location"* ]]; then
            LOCATIONOK=true
        fi
    done
    if [ -z "$LOCATIONOK" ]; then
        bashio::log.red "Watch-out: your CONFIG_LOCATION values can only be set in /share, /config or /data (internal to addon). It will be reset to the default location: $CONFIGLOCATION/config.yaml"
        CONFIGSOURCE="$CONFIGLOCATION"/config.yaml
    fi
fi

# Migrate if needed
if [[ "$CONFIGLOCATION" == "/config" ]]; then
    # Migrate file
    if [ -f "/homeassistant/addons_config/${slug}/config.yaml" ] && [ ! -L "/homeassistant/addons_config/${slug}" ]; then
        echo "Migrating config.yaml to new config location"
        mv "/homeassistant/addons_config/${slug}/config.yaml" /config/config.yaml
    fi
    # Migrate option
    if [[ "$(bashio::config "CONFIG_LOCATION")" == "/config/addons_config"* ]] && [ -f /config/config.yaml ]; then
        bashio::addon.option "CONFIG_LOCATION" "/config/config.yaml"
        CONFIGSOURCE="/config/config.yaml"
    fi
fi

if [[ "$CONFIGSOURCE" != *".yaml" ]]; then
    bashio::log.error "Something is going wrong in the config location, quitting"
    exit 1
fi

ENV_FILE="/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    printf '# Generated by 01-config_yaml.sh from %s\n' "$CONFIGSOURCE" > "$ENV_FILE"
fi

# Permissions only if the config file already exists
if [[ "$CONFIGSOURCE" == *".yaml" ]] && [ -f "$CONFIGSOURCE" ]; then
    echo "Setting permissions for the config.yaml directory"
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    chmod -R 755 "$(dirname "${CONFIGSOURCE}")" 2> /dev/null
fi

####################
# LOAD CONFIG.YAML #
####################

# Exit if the config file is absent
if [ ! -f "$CONFIGSOURCE" ]; then
    exit 0
fi

# Check if there are lines to read
cp "$CONFIGSOURCE" /tempenv
sed -i '/^#/d' /tempenv
sed -i '/^[[:space:]]*$/d' /tempenv
sed -i '/^$/d' /tempenv

# Exit if empty
if [ ! -s /tempenv ]; then
    rm /tempenv
    mv "$CONFIGSOURCE" "$CONFIGSOURCE".old
    exit 0
fi

echo "" >> /tempenv

echo ""
bashio::log.green "Load environment variables from $CONFIGSOURCE if existing"
if [[ "$CONFIGSOURCE" == "/config"* ]]; then
    bashio::log.green "If accessing the file with filebrowser it should be mapped to $CONFIGFILEBROWSER"
else
    bashio::log.green "If accessing the file with filebrowser it should be mapped to $CONFIGSOURCE"
fi
bashio::log.warning "This methodology is deprecated, please convert your Environment variables to the addon options env_vars. Instructions can be found here : https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
echo ""

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed /tempenv &> ERROR || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
    cat ERROR
    bashio::log.yellow "... config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
fi

# converts yaml to variables
sed -i 's/: /=/' /tempenv

# Look where secrets.yaml is located
SECRETSFILE="/config/secrets.yaml"
if [ ! -f "$SECRETSFILE" ]; then SECRETSFILE="/homeassistant/secrets.yaml"; fi

# --- minimal helper: append line only if missing
append_unique_line() {
    # $1=file, $2=line
    local _file="$1"
    local _line="$2"
    mkdir -p "$(dirname "$_file")" 2>/dev/null || true
    touch "$_file" 2>/dev/null || true
    grep -qxF -- "$_line" "$_file" 2>/dev/null || echo "$_line" >> "$_file"
}

while IFS= read -r line; do
    # Skip empty lines
    if [[ -z "$line" ]]; then
        continue
    fi

    # Check if secret
    if [[ "$line" == *!secret* ]]; then
        echo "Secret detected"
        if [ ! -f "$SECRETSFILE" ]; then
            bashio::log.fatal "Secrets file not found in $SECRETSFILE, $line skipped"
            continue
        fi
        secret=$(echo "$line" | sed 's/.*!secret \(.*\)/\1/')
        # Check if single match
        secretnum=$(sed -n "/$secret:/=" "$SECRETSFILE")
        if [[ $(echo "$secretnum" | grep -q ' ') ]]; then
            bashio::exit.nok "There are multiple matches for your password name. Please check your secrets.yaml file"
        fi
        # Get text
        secret_value=$(sed -n "/$secret:/s/.*: //p" "$SECRETSFILE")
        line="${line%%=*}='$secret_value'"
    fi

    # Data validation
    if [[ "$line" =~ ^[^[:space:]]+.+[=].+$ ]]; then
        # extract keys and values
        KEYS="${line%%=*}"
        VALUE="${line#*=}"
        line="${KEYS}=${VALUE}"
        export "$line"

        # export to python
        if command -v "python3" &> /dev/null; then
            [ ! -f /env.py ] && echo "import os" > /env.py
            # Escape single quotes in VALUE
            VALUE_ESCAPED="${VALUE//\'/\'\"\'\"\'}"
            echo "os.environ['${KEYS}'] = '${VALUE_ESCAPED}'" >> /env.py
            python3 /env.py
        fi

        # set .env
        echo "$line" >> "$ENV_FILE"

        # set environment
        mkdir -p /etc
        echo "$line" >> /etc/environment

        # Export to entrypoint
        if [ -f /entrypoint.sh ]; then sed -i "1a export $line" /entrypoint.sh 2> /dev/null; fi
        if [ -f /*/entrypoint.sh ]; then sed -i "1a export $line" /*/entrypoint.sh 2> /dev/null; fi

        # Export to scripts
        if cat /etc/services.d/*/*run* &> /dev/null; then sed -i "1a export $line" /etc/services.d/*/*run* 2> /dev/null; fi
        if cat /etc/cont-init.d/*run* &> /dev/null; then sed -i "1a export $line" /etc/cont-init.d/*run* 2> /dev/null; fi

        # For s6
        if [ -d /var/run/s6/container_environment ]; then printf "%s" "${VALUE}" > /var/run/s6/container_environment/"${KEYS}"; fi

        # Persist for interactive shells
        if [[ -n "${HOME:-}" ]]; then
            mkdir -p "$HOME"
            append_unique_line "$HOME/.bashrc" "export $line"
        fi
        append_unique_line "/etc/bash.bashrc" "export $line"

        # Show in log
        if ! bashio::config.false "verbose"; then bashio::log.blue "$line"; fi
    else
        bashio::log.red "Skipping line that does not follow the correct structure: $line"
    fi
done < "/tempenv"

rm /tempenv
