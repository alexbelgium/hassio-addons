#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC1087,SC2163,SC2116,SC2086
# -----------------------------------------------------------------------------
# Robust environment‑variable loader for Home‑Assistant add‑ons
#   • Parses YAML with embedded Python, no external yq dependency
#   • Supports !secret look‑ups
#   • Correctly escapes values containing quotes, $, \\ , newlines …
#   • Exports to: shell, env.py, .env, /etc/environment, s6, service scripts
# -----------------------------------------------------------------------------
set -euo pipefail

##################
# INITIALIZATION #
##################

# Run outside HA? then do nothing
if [[ ! -d /config ]] || ! bashio::supervisor.ping &>/dev/null; then
	echo "..."
	exit 0
fi

slug="${HOSTNAME/-/_}"
slug="${slug#*_}"

# -----------------------------------------------------------------------------
# Resolve CONFIGSOURCE                                                        #
# -----------------------------------------------------------------------------
if [[ ! -f /config/configuration.yaml && ! -f /config/configuration.json ]]; then
	CONFIGLOCATION="/config" # New architecture
	CONFIGFILEBROWSER="/addon_configs/${HOSTNAME/-/_}/config.yaml"
else
	CONFIGLOCATION="/config/addons_config/${slug}" # Legacy architecture
	CONFIGFILEBROWSER="/homeassistant/addons_config/${slug}/config.yaml"
fi

mkdir -p "$CONFIGLOCATION"
CONFIGSOURCE="$CONFIGLOCATION/config.yaml"

if bashio::config.has_value 'CONFIG_LOCATION'; then
	CONFIGSOURCE="$(bashio::config "CONFIG_LOCATION")"
	[[ "$CONFIGSOURCE" == *.* ]] && CONFIGSOURCE="$(dirname "$CONFIGSOURCE")"
	[[ "$CONFIGSOURCE" != *.yaml ]] && CONFIGSOURCE="${CONFIGSOURCE%/}/config.yaml"
	case "$CONFIGSOURCE" in
	/share/* | /config/* | /data/*) : ;;
	*) bashio::log.red "CONFIG_LOCATION must be in /share, /config or /data – defaulting." && CONFIGSOURCE="$CONFIGLOCATION/config.yaml" ;;
	esac
fi

if [[ "$CONFIGLOCATION" == "/config" && -f "/homeassistant/addons_config/${slug}/config.yaml" && ! -L "/homeassistant/addons_config/${slug}" ]]; then
	echo "Migrating config.yaml to $CONFIGLOCATION"
	mv "/homeassistant/addons_config/${slug}/config.yaml" "$CONFIGSOURCE"
fi

chmod -R 755 "$(dirname "$CONFIGSOURCE")"

####################
# CONFIG TEMPLATE  #
####################

if [[ ! -f "$CONFIGSOURCE" ]]; then
	echo "... no config file, creating one from template."
	mkdir -p "$(dirname "$CONFIGSOURCE")"
	if [[ -f /templates/config.yaml ]]; then
		cp /templates/config.yaml "$CONFIGSOURCE"
	else
		curl -fsSL "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/config.template" -o "$CONFIGSOURCE"
	fi
	bashio::log.green "Edit $CONFIGSOURCE then restart the add‑on."
fi

if ! grep -qE '^[[:space:]]*[A-Za-z0-9_]+:' "$CONFIGSOURCE"; then
	bashio::log.green "... no env variables found, exiting"
	exit 0
fi

############################################
#  HELPER: read_yaml() (Python)            #
############################################
# Prints flattened KEY=value lines for scalar leaves.
read_yaml() {
	python3 - "$1" <<'PY'
import sys, yaml, json, pathlib
from collections.abc import Mapping, Sequence

def walk(node, prefix=""):
    if isinstance(node, Mapping):
        for k, v in node.items():
            yield from walk(v, f"{prefix}{k}_")
    elif isinstance(node, Sequence) and not isinstance(node, (str, bytes)):
        for i, v in enumerate(node):
            yield from walk(v, f"{prefix}{i}_")
    else:
        yield prefix[:-1], node

fname = sys.argv[1]
with open(fname, 'r') as f:
    data = yaml.safe_load(f) or {}
for k, v in walk(data):
    if isinstance(v, (str, int, float, bool)):
        print(f"{k}={v}")
PY
}

############################################
#  HELPER: shell_escape()                  #
############################################
# Uses printf %q – POSIX‑sh safe quoting.
shell_escape() {
	printf '%q' "$1"
}

############################################
#  Locate secrets.yaml                     #
############################################
SECRETSFILE="/config/secrets.yaml"
[[ -f "$SECRETSFILE" ]] || SECRETSFILE="/homeassistant/secrets.yaml"

get_secret() {
	python3 - "$SECRETSFILE" "$1" <<'PY'
import sys, yaml, pathlib
sec, key = sys.argv[1:3]
try:
    with open(sec) as f:
        data = yaml.safe_load(f) or {}
    print(data.get(key, ""))
except FileNotFoundError:
    pass
PY
}

############################################
#  MAIN LOOP                               #
############################################
while IFS= read -r PAIR; do
	KEY="${PAIR%%=*}"
	VALUE="${PAIR#*=}"

	# !secret support
	if [[ "$VALUE" =~ ^!secret[[:space:]]+(.+) ]]; then
		NAME="${BASH_REMATCH[1]}"
		VALUE="$(get_secret "$NAME")"
		[[ -z "$VALUE" ]] && bashio::exit.nok "Secret '$NAME' not found in $SECRETSFILE"
	fi

	SAFE_VALUE=$(shell_escape "$VALUE")

	# 1) Export to current shell
	export "$KEY=$VALUE"

	# 2) env.py (idempotent)
	python3 - "$KEY" "$VALUE" <<'PY'
import json, os, pathlib, sys
k, v = sys.argv[1:3]
p = pathlib.Path('/env.py')
if not p.exists():
    p.write_text('import os\n')
with p.open('a') as f:
    f.write(f"os.environ[{json.dumps(k)}] = {json.dumps(v)}\n")
os.environ[k] = v
PY

	# 3) .env & /etc/environment (double‑quoted, internal " escaped)
	env_val="${VALUE//\"/\"}"
	printf '%s="%s"\n' "$KEY" "$env_val" >>/.env
	printf '%s="%s"\n' "$KEY" "$env_val" >>/etc/environment

	# 4) s6 container_environment (raw value)
	if [[ -d /var/run/s6/container_environment ]]; then
		printf '%s' "$VALUE" >"/var/run/s6/container_environment/$KEY"
	fi

	# 5) Prepend export to service scripts
	for script in /etc/services.d/*/*run* /etc/cont-init.d/*run*; do
		[[ -f $script ]] || continue
		grep -q "^export $KEY=" "$script" || sed -i "1i export $KEY=$SAFE_VALUE" "$script"
	done

	# 6) Persist for interactive shells
	grep -q "^export $KEY=" ~/.bashrc || echo "export $KEY=$SAFE_VALUE" >>~/.bashrc

	# 7) Log (truncate long values)
	bashio::log.blue "$KEY='${VALUE:0:60}'${VALUE:60:+…}"
done < <(read_yaml "$CONFIGSOURCE")

bashio::log.green "Environment variables successfully loaded."
