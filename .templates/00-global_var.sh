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

    # Exact key match at start of line; ignore comments
    line="$(
        awk -v k="$name" '
            /^[[:space:]]*#/ {next}
            $0 ~ "^[[:space:]]*" k ":[[:space:]]*" {
                sub("^[[:space:]]*" k ":[[:space:]]*", "", $0)
                print
                exit
            }
        ' "$SECRETSOURCE"
    )"

    [[ -n "$line" ]] || bashio::exit.nok "Secret $name not found"
    printf '%s' "$line"
}

################################################################################
# Quoting
################################################################################
dotenv_quote() {
    # For /.env and /etc/environment: double quotes + minimal escaping
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    v="${v//$'\n'/\\n}"
    v="${v//$'\r'/\\r}"
    printf '"%s"' "$v"
}

shell_quote() {
    # Single-quote for safe injection in shell code
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
    local k="$1" v="$2" q
    q="$(shell_quote "$v")"

    awk -v k="$k" -v q="$q" -v e="$BLOCK_END" '
        $0==e { print "export " k "=" q }
        { print }
    ' "$EXPORT_BLOCK" > "$EXPORT_BLOCK.tmp"
    mv "$EXPORT_BLOCK.tmp" "$EXPORT_BLOCK"
}

inject_block() {
    local f="$1" tmp
    tmp="$(mktemp_safe)"

    awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" -v bf="$EXPORT_BLOCK" '
        function emit(){ while((getline l<bf)>0) print l; close(bf) }
        BEGIN{ skip=0; injected=0 }
        {
            if($0==b){ skip=1; if(!injected){ emit(); injected=1 } next }
            if($0==e){ skip=0; next }
            if(skip) next

            if(NR==1 && $0~/^#!/){
                print
                if(!injected){ emit(); injected=1 }
                next
            }
            print
        }
        END{ if(!injected) emit() }
    ' "$f" > "$tmp"

    cat "$tmp" > "$f"
    rm -f "$tmp"
}

################################################################################
# Export handler
################################################################################
export_var() {
    local k="$1" v="$2"

    # Valid env var identifier only
    [[ "$k" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
        bashio::log.warning "Skipping invalid env var name: $k"
        return 0
    }

    v="$(resolve_secret "$v")"

    if [[ "${k,,}" =~ pass|token|secret|apikey|api_key|private|pwd|key ]]; then
        bashio::log.blue "$k=******"
    else
        bashio::log.blue "$k=$v"
    fi

    # Runtime environment (no eval, safe for special chars)
    export "$k=$v"

    # S6 environment (preferred for services)
    if [[ -d /var/run/s6/container_environment ]]; then
        printf '%s' "$v" > "/var/run/s6/container_environment/$k"
    fi

    # Queue for .env and /etc/environment (written once, idempotent)
    echo "$k=$(dotenv_quote "$v")" >> "$KV_FILE"

    # Add to injected export block for scripts
    append_export "$k" "$v"
}

################################################################################
# JSON parsing (jq bug fixed: use "? //", not "?//")
################################################################################
while IFS= read -r -d $'\0' k && IFS= read -r v; do
    export_var "$k" "$v"
done < <(
    jq -r '
        def emit(k; v): "\((k|tostring))\u0000\((v|tostring))";

        . as $root
        | (
            # 1) env_vars[] (supported shapes)
            ($root.env_vars? // [])[] as $e
            | if ($e|type) == "object" then
                  if ($e|has("name") and has("value")) then
                      emit($e.name; ($e.value // ""))
                  else
                      $e|to_entries[]|emit(.key; (.value // ""))
                  end
              else
                  # string "KEY=VALUE" form (value may contain '=')
                  ($e|tostring) as $s
                  | if ($s|test("^[^=]+=")) then
                        ($s|capture("^(?<k>[^=]+)=(?<v>.*)$")) as $m
                        | emit($m.k; $m.v)
                    else empty end
              end
          ),
          (
            # 2) top-level scalar options excluding env_vars
            $root
            | to_entries[]
            | select(.key != "env_vars")
            | select((.value|type) != "object" and (.value|type) != "array" and (.value|type) != "null")
            | emit(.key; .value)
          )
    ' "$JSONSOURCE"
)

################################################################################
# Write .env and /etc/environment (idempotent: replace whole file content)
# Notes:
# - /.env is commonly used by apps expecting dotenv format
# - /etc/environment is read by PAM/system tooling; KEY="value" is acceptable
################################################################################
{
    echo "$BLOCK_BEGIN"
    cat "$KV_FILE"
    echo "$BLOCK_END"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
cp "$ENV_FILE" "$ETC_ENV_FILE"

################################################################################
# Inject into scripts and shells (best-effort)
################################################################################
for f in /etc/services.d/*/run /etc/cont-init.d/*.sh /entrypoint.sh /etc/bash.bashrc; do
    [[ -f "$f" ]] && inject_block "$f"
done

if [[ -n "${HOME:-}" ]]; then
    mkdir -p "$HOME"
    touch "$HOME/.bashrc"
    inject_block "$HOME/.bashrc"
fi

################################################################################
# Timezone (best-effort)
################################################################################
set +e
if [[ -n "$TZ" && -f "/usr/share/zoneinfo/$TZ" ]]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi
