#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

################################################################################
# Guard: only run inside Supervisor-managed add-ons
################################################################################
if ! bashio::supervisor.ping 2>/dev/null; then
    echo "..."
    exit 0
fi

echo ""
bashio::log.notice "Converting addon options to environment variables"
bashio::log.notice "Supports custom env_vars"
bashio::log.notice "https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2"
echo ""

################################################################################
# Inputs
################################################################################
JSONSOURCE="/data/options.json"
ENV_FILE="/.env"
ETC_ENV_FILE="/etc/environment"

[[ -f "$JSONSOURCE" ]] || bashio::exit.nok "Missing $JSONSOURCE"
command -v jq >/dev/null || bashio::exit.nok "jq is required"

mkdir -p /etc
touch "$ETC_ENV_FILE"

################################################################################
# Temp helper
################################################################################
mktemp_safe() {
    local tmpdir="${TMPDIR:-/tmp}"
    mkdir -p "$tmpdir"
    mktemp "$tmpdir/tmp.XXXXXXXXXX"
}

################################################################################
# Secrets support
################################################################################
SECRETSOURCE=""
[[ -f /homeassistant/secrets.yaml ]] && SECRETSOURCE="/homeassistant/secrets.yaml"
[[ -z "$SECRETSOURCE" && -f /config/secrets.yaml ]] && SECRETSOURCE="/config/secrets.yaml"

resolve_secret() {
    local v="$1" name line
    [[ "$v" =~ ^[[:space:]]*\!secret[[:space:]]+(.+)$ ]] || { printf '%s' "$v"; return; }
    name="${BASH_REMATCH[1]}"
    [[ -n "$SECRETSOURCE" ]] || bashio::exit.nok "Secrets not mounted"
    line="$(awk -v k="$name" '$1==k":"{sub("^[^:]+:[[:space:]]*","");print;exit}' "$SECRETSOURCE")"
    [[ -n "$line" ]] || bashio::exit.nok "Secret $name not found"
    printf '%s' "$line"
}

################################################################################
# Quoting
################################################################################
dotenv_quote() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    v="${v//$'\n'/\\n}"
    printf '"%s"' "$v"
}

shell_quote() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\'/\'\"\'\"\' }"
    s="${s% }"
    printf "'%s'" "$s"
}

################################################################################
# S6 + script injection block
################################################################################
BLOCK_BEGIN="# --- BEGIN ADDON ENV (generated) ---"
BLOCK_END="# --- END ADDON ENV (generated) ---"

EXPORT_BLOCK="$(mktemp_safe)"
KV_FILE="$(mktemp_safe)"
trap 'rm -f "$EXPORT_BLOCK" "$KV_FILE"' EXIT

{
    echo "$BLOCK_BEGIN"
    echo "# Generated from $JSONSOURCE"
    echo "$BLOCK_END"
} > "$EXPORT_BLOCK"

append_export() {
    local k="$1" v="$2"
    local q
    q="$(shell_quote "$v")"
    awk -v k="$k" -v q="$q" -v e="$BLOCK_END" '$0==e{print "export "k"="q}1' "$EXPORT_BLOCK" > "$EXPORT_BLOCK.tmp"
    mv "$EXPORT_BLOCK.tmp" "$EXPORT_BLOCK"
}

inject_block() {
    local f="$1" tmp
    tmp="$(mktemp_safe)"
    awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" -v bf="$EXPORT_BLOCK" '
    function emit(){while((getline l<bf)>0)print l;close(bf)}
    BEGIN{p=0}
    {
        if($0==b){skip=1;emit();next}
        if($0==e){skip=0;next}
        if(skip)next
        if(NR==1 && $0~/^#!/){print;emit();next}
        print
    }
    END{if(!skip)emit()}
    ' "$f" > "$tmp"
    cat "$tmp" > "$f"
    rm -f "$tmp"
}

################################################################################
# Export handler
################################################################################
export_var() {
    local k="$1" v="$2"

    [[ "$k" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return

    v="$(resolve_secret "$v")"

    if [[ "${k,,}" =~ pass|token|secret|key ]]; then
        bashio::log.blue "$k=******"
    else
        bashio::log.blue "$k=$v"
    fi

    export "$k=$v"

    [[ -d /var/run/s6/container_environment ]] && printf '%s' "$v" > "/var/run/s6/container_environment/$k"

    echo "$k=$(dotenv_quote "$v")" >> "$KV_FILE"
    append_export "$k" "$v"
}

################################################################################
# JSON parsing (safe + jq bug fixed)
################################################################################
while IFS= read -r -d $'\0' k && IFS= read -r v; do
    export_var "$k" "$v"
done < <(
jq -r '
def emit(k;v): "\((k|tostring))\u0000\((v|tostring))";
. as $root
|
(
 ($root.env_vars?//[])[]? as $e
 | if $e|type=="object" then
      if $e|has("name") and has("value") then emit($e.name;$e.value)
      else $e|to_entries[]|emit(.key;.value) end
   else
      ($e|tostring) as $s
      | if $s|test("=") then
           ($s|capture("^(?<k>[^=]+)=(?<v>.*)$"))|emit(.k;.v)
        else empty end
   end
),
(
 $root|to_entries[]
 | select(.key!="env_vars")
 | select((.value|type)!="object" and (.value|type)!="array")
 | emit(.key;.value)
)
' "$JSONSOURCE"
)

################################################################################
# Write .env and /etc/environment (idempotent)
################################################################################
{
    echo "$BLOCK_BEGIN"
    cat "$KV_FILE"
    echo "$BLOCK_END"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
cp "$ENV_FILE" "$ETC_ENV_FILE"

################################################################################
# Inject into scripts and shells
################################################################################
for f in /etc/services.d/*/run /etc/cont-init.d/*.sh /entrypoint.sh /etc/bash.bashrc "$HOME/.bashrc"; do
    [[ -f "$f" ]] && inject_block "$f"
done

################################################################################
# Timezone
################################################################################
set +e
if [[ -n "$TZ" && -f "/usr/share/zoneinfo/$TZ" ]]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi
