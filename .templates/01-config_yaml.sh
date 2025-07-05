#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

slug="${HOSTNAME/-/_}"
slug="${slug#*_}"

# CONFIG FILE
if [[ ! -f /config/configuration.yaml && ! -f /config/configuration.json ]]; then
	CONFIGLOCATION="/config"
else
	CONFIGLOCATION="/config/addons_config/${slug}"
fi

mkdir -p "$CONFIGLOCATION"
CONFIGSOURCE="$CONFIGLOCATION/config.yaml"

if bashio::config.has_value 'CONFIG_LOCATION'; then
	CONFIGSOURCE="$(bashio::config "CONFIG_LOCATION")"
	[[ "$CONFIGSOURCE" == *.* ]] && CONFIGSOURCE="$(dirname "$CONFIGSOURCE")"
	[[ "$CONFIGSOURCE" != *.yaml ]] && CONFIGSOURCE="${CONFIGSOURCE%/}/config.yaml"
	case "$CONFIGSOURCE" in
	/share/* | /config/* | /data/*) : ;;
	*) bashio::log.red "CONFIG_LOCATION must be in /share, /config or /data – reverting." && CONFIGSOURCE="$CONFIGLOCATION/config.yaml" ;;
	esac
fi

if [[ "$CONFIGLOCATION" == "/config" && -f "/homeassistant/addons_config/${slug}/config.yaml" && ! -L "/homeassistant/addons_config/${slug}" ]]; then
	echo "Migrating config.yaml to $CONFIGLOCATION"
	mv "/homeassistant/addons_config/${slug}/config.yaml" "$CONFIGSOURCE"
fi

chmod -R 755 "$(dirname "$CONFIGSOURCE")"

HAS_PYTHON=false
command -v python3 &>/dev/null && HAS_PYTHON=true
HAS_YQ=false
command -v yq &>/dev/null && HAS_YQ=true

$HAS_PYTHON || bashio::log.yellow "python3 not found – /env.py export disabled."
$HAS_YQ || bashio::exit.nok "yq not found – script not executed."

if [[ ! -f "$CONFIGSOURCE" ]]; then
	echo "… no config file, creating one from template."
	mkdir -p "$(dirname "$CONFIGSOURCE")"
	if [[ -f /templates/config.yaml ]]; then
		cp /templates/config.yaml "$CONFIGSOURCE"
	else
		curl -fsSL "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/config.template" -o "$CONFIGSOURCE"
	fi
	bashio::log.green "Edit $CONFIGSOURCE then restart the add‑on."
fi

shell_escape() { printf '%q' "$1"; }

# Prints key=value from YAML, ignoring comments/underscored keys
read_config() {
	local file="$1"
	yq eval 'to_entries | .[] | select(.key|test("^[#_]")|not) | "\(.key)=\(.value | @sh)"' "$file" 2>/dev/null
}

SECRETSFILE="/config/secrets.yaml"
[[ -f "$SECRETSFILE" ]] || SECRETSFILE="/homeassistant/secrets.yaml"
get_secret() {
	local name="$1"
	yq eval ".${name}" "$SECRETSFILE" 2>/dev/null || true
}

# Safe double-quote for .env and /etc/environment (bash and python compatible)
dq_escape() {
	# Escape only embedded double quotes and dollar signs for shell (not for YAML)
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g'
}

while IFS= read -r LINE; do
	[[ -z "$LINE" || "$LINE" != *=* ]] && continue
	KEY="${LINE%%=*}"
	VALUE="${LINE#*=}"
	# !secret handling
	if [[ "$VALUE" =~ ^!secret[[:space:]]+(.+) ]]; then
		NAME="${BASH_REMATCH[1]}"
		VALUE="$(get_secret "$NAME")"
		[[ -z "$VALUE" ]] && bashio::exit.nok "Secret '$NAME' not found in $SECRETSFILE"
	fi
	VALUE="${VALUE##[[:space:]]}"
	VALUE="${VALUE%%[[:space:]]}"
	SAFE_VALUE=$(shell_escape "$VALUE")
	export "$KEY=$VALUE"
	if $HAS_PYTHON; then
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
	fi
	env_val=$(dq_escape "$VALUE")
	printf '%s="%s"\n' "$KEY" "$env_val" >>/.env
	printf '%s="%s"\n' "$KEY" "$env_val" >>/etc/environment
	[[ -d /var/run/s6/container_environment ]] && printf '%s' "$VALUE" >"/var/run/s6/container_environment/$KEY"
	for script in /etc/services.d/*/*run* /etc/cont-init.d/*run*; do
		[[ -f $script ]] || continue
		grep -q "^export $KEY=" "$script" || sed -i "1i export $KEY=$SAFE_VALUE" "$script"
	done
	grep -q "^export $KEY=" ~/.bashrc || echo "export $KEY=$SAFE_VALUE" >>~/.bashrc
	bashio::log.blue "$KEY='${VALUE:0:60}'${VALUE:60:+…}"
done < <(read_config "$CONFIGSOURCE")

bashio::log.green "Environment variables successfully loaded."
