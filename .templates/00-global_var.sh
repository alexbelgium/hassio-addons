#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

################################################################################
# Block markers, temp helper, quoting and export-block builders
#
# Everything here is free of side effects and defined before the Supervisor
# guard, so that the self-test below can exercise the whole value path outside a
# container, where bashio is not available.
################################################################################
BLOCK_BEGIN="# --- BEGIN ADDON ENV (generated) ---"
BLOCK_END="# --- END ADDON ENV (generated) ---"

mktemp_safe() {
    local tmpdir="${TMPDIR:-/tmp}"
    mkdir -p "$tmpdir"
    mktemp "$tmpdir/tmp.XXXXXXXXXX"
}

dotenv_quote() {
    # For /.env and /etc/environment: double quotes + minimal escaping.
    #
    # These files are read back by sourcing them from a shell, so every
    # character that is still special inside double quotes has to be escaped.
    # $ and ` used to be left alone, which meant a value was expanded instead of
    # being read literally: a password like pa$$w0rd came back with the shell
    # PID spliced into it, and a value containing backticks ran as a command.
    #
    # Backslash must be doubled first, so that the backslashes added below are
    # not doubled in turn.
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    v="${v//\$/\\\$}"
    v="${v//\`/\\\`}"
    v="${v//$'\n'/\\n}"
    v="${v//$'\r'/\\r}"
    printf '"%s"' "$v"
}

shell_quote() {
    # Single-quote for safe injection into shell code.
    #
    # Inside single quotes every character is literal, so the only thing a value
    # needs escaping for is the quote character itself: close the quote, emit an
    # escaped quote, reopen it. Backslashes must be left untouched.
    #
    # This used to double every backslash and to replace ' with '"'"' followed by
    # a stray space. The stray space corrupted every value containing a quote
    # (O'Brien pass arrived as O' Brien pass); the doubling was undone further
    # down the path by the "awk -v" in append_export, so backslashes survived by
    # accident. Both halves are fixed together -- see the note in append_export.
    local s="$1"
    printf "'%s'" "${s//\'/\'\\\'\'}"
}

append_export() {
    # Plain append, deliberately not awk: "awk -v q=$value" runs the value
    # through awk's escape processing, which turns \t into a tab, \b into a
    # backspace and \\ into a single backslash. That used to be cancelled out by
    # shell_quote doubling every backslash, so the two bugs hid each other --
    # fixing only one of them corrupts the value.
    printf 'export %s=%s\n' "$1" "$(shell_quote "$2")" >> "$EXPORT_BODY"
}

compose_export_block() {
    {
        echo "$BLOCK_BEGIN"
        echo "# Generated from $JSONSOURCE"
        cat "$EXPORT_BODY"
        echo "$BLOCK_END"
    } > "$EXPORT_BLOCK"
}

################################################################################
# Self-test: bash .templates/00-global_var.sh --self-test
#
# Builds a real export block and sources it, which is exactly what happens once
# the block is injected at the top of a service run script, then checks that
# every value came back byte for byte. Testing the whole path matters: the two
# defects this guards against (shell_quote doubling backslashes and append_export
# passing values through "awk -v") cancelled each other out, so a test of either
# helper alone reported success while the pair was wrong.
#
# Runs before the Supervisor guard and exits, so it never affects startup.
################################################################################
if [[ "${1:-}" == "--self-test" ]]; then
    # Literal test data: the single quotes and metacharacters are the point.
    # shellcheck disable=SC2016
    self_test_values=(
        'plain.host'
        'next\.duckdns\.org'   # regex, dots escaped once
        'next\\.duckdns\\.org' # regex, dots escaped twice by the user
        'C:\Users\bob\share'   # windows path, \U and \b are awk escapes
        '\\server\share'       # UNC path
        'col\tsep'             # \t is an awk escape
        "O'Brien pass"         # embedded quote
        "it's a 'quoted' word" # several embedded quotes
        "'leading"
        "trailing'"
        'a$b`c"d' # shell metacharacters
        '*.example.com|^foo\d+$'
        $'sp ace\ttab'
        ''
    )

    JSONSOURCE="self-test"
    EXPORT_BODY="$(mktemp_safe)"
    EXPORT_BLOCK="$(mktemp_safe)"
    self_test_env="$(mktemp_safe)"
    trap 'rm -f "$EXPORT_BODY" "$EXPORT_BLOCK" "$self_test_env"' EXIT
    self_test_rc=0

    self_test_check() {
        # $1 name of the variable that was read back, $2 expected value, $3 how
        local self_test_got="${!1}"
        [[ "$self_test_got" == "$2" ]] && return 0
        printf 'FAIL (%s): <%s> came back as <%s>\n' "$3" "$2" "$self_test_got"
        self_test_rc=1
    }

    # 1. The export block, sourced the way an injected run script would
    for self_test_i in "${!self_test_values[@]}"; do
        append_export "SELFTEST_${self_test_i}" "${self_test_values[$self_test_i]}"
    done
    compose_export_block
    # shellcheck source=/dev/null
    . "$EXPORT_BLOCK"
    for self_test_i in "${!self_test_values[@]}"; do
        self_test_check "SELFTEST_${self_test_i}" "${self_test_values[$self_test_i]}" "export block"
    done

    # 2. /.env, sourced the way browserless_chrome and wger read it back.
    # Values holding a newline are out of scope: dotenv_quote writes them as a
    # literal \n, which a dotenv parser unescapes but a shell does not.
    for self_test_i in "${!self_test_values[@]}"; do
        printf 'DOTENVTEST_%s=%s\n' \
            "$self_test_i" "$(dotenv_quote "${self_test_values[$self_test_i]}")"
    done > "$self_test_env"
    if ! bash -n "$self_test_env"; then
        # An unescaped backtick or quote leaves the file unparseable, which would
        # abort the sourcing shell instead of just yielding a wrong value.
        echo "FAIL (dotenv): generated env file is not valid shell"
        self_test_rc=1
    else
        # shellcheck source=/dev/null
        . "$self_test_env"
        for self_test_i in "${!self_test_values[@]}"; do
            self_test_check "DOTENVTEST_${self_test_i}" "${self_test_values[$self_test_i]}" "dotenv"
        done
    fi

    [[ "$self_test_rc" -eq 0 ]] &&
        echo "${#self_test_values[@]} values round-tripped unchanged (export block + dotenv)"
    exit "$self_test_rc"
fi

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
# S6 + script injection block
################################################################################
EXPORT_BLOCK="$(mktemp_safe)"
EXPORT_BODY="$(mktemp_safe)"
KV_FILE="$(mktemp_safe)"
trap 'rm -f "$EXPORT_BLOCK" "$EXPORT_BODY" "$KV_FILE"' EXIT

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
# Order: 1) top-level addon options first, 2) env_vars second (can override)
################################################################################
while IFS= read -r -d $'\0' k && IFS= read -r v; do
    export_var "$k" "$v"
done < <(
    jq -r '
        def emit(k; v): "\((k|tostring))\u0000\((v|tostring))";

        . as $root
        | (
            # 1) top-level scalar options excluding env_vars (processed first)
            $root
            | to_entries[]
            | select(.key != "env_vars")
            | select((.value|type) != "object" and (.value|type) != "array" and (.value|type) != "null")
            | emit(.key; .value)
          ),
          (
            # 2) env_vars[] (processed second, overrides addon options if same key)
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
compose_export_block

for f in /etc/services.d/*/run /etc/s6-overlay/s6-rc.d/*/run /etc/cont-init.d/*.sh /entrypoint.sh /etc/bash.bashrc "${GLOBAL_VAR_FILES:-}"; do
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
