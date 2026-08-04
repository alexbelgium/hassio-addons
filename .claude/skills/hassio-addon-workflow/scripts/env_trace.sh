#!/usr/bin/env bash
# Trace one env var through the whole add-on plumbing, to answer "I set the option and nothing
# happened".
#
# This is the single highest-value diagnostic for this repo, because the plumbing has four
# separate stages and a value can be present at stage 3 and absent at stage 4 while every script
# involved reports success. That exact case shipped: MAX_RES was correctly written to
# /run/s6/container_environment/MAX_RES six seconds before Xvfb started, and Xvfb still came up
# at the base-image default.
#
# The four stages:
#   1. /data/options.json          the user's saved add-on options
#   2. injected export block       .templates/00-global_var.sh writes `export <option>='<v>'`
#                                  into every service run script — as cont-init 00, i.e. BEFORE
#                                  any higher-numbered cont-init script can influence it
#   3. container_environment       s6's envdir, read only by services using `with-contenv`
#   4. the running process         the only stage that actually matters
#
# Two consequences worth internalising:
#   * A cont-init.d script numbered >00 cannot change what stage 2 injected.
#   * A service starting `#!/usr/bin/env bashio` (LSIO's svc-xorg does) never reads stage 3, so
#     writing container_environment for it is a silent no-op.
#
# Usage: env_trace.sh <VAR> [process-name-or-pid]
#   env_trace.sh MAX_RES Xvfb
#   env_trace.sh DRINODE Xvfb        # a working example, for comparison
set -uo pipefail

VAR="${1:?usage: env_trace.sh <VAR> [process-name-or-pid]}"
TARGET="${2:-}"

echo "== tracing ${VAR} =="
echo

echo "1. /data/options.json (the user's saved options)"
if [ -f /data/options.json ]; then
    python3 - "$VAR" <<'PY'
import json, sys
var = sys.argv[1]
try:
    opts = json.load(open('/data/options.json'))
except Exception as err:
    print(f"   could not parse: {err}"); raise SystemExit
hit = {k: v for k, v in opts.items() if k.lower() == var.lower()}
if hit:
    for k, v in hit.items():
        shown = '<empty string>' if v == '' else repr(v)
        print(f"   {k} = {shown}")
        if k != var:
            print(f"   NOTE: option is named '{k}', not '{var}' — the injected export uses the")
            print(f"         option name verbatim, so a service reading ${var} will not see it.")
else:
    print(f"   absent (so the add-on default from config.yaml applies, if any)")
PY
else
    echo "   /data/options.json not present (not running as an add-on?)"
fi

echo
echo "2. injected 'ADDON ENV' export block in service run scripts"
found=0
for d in /etc/s6-overlay/s6-rc.d /etc/services.d; do
    [ -d "$d" ] || continue
    while IFS= read -r rs; do
        if grep -qE "^export ${VAR}=" "$rs" 2> /dev/null; then
            echo "   $(grep -E "^export ${VAR}=" "$rs" | head -1)   <- $rs"
            found=1
        fi
    done < <(find "$d" -name run -type f 2> /dev/null)
done
[ "$found" -eq 0 ] && echo "   ${VAR} not injected into any service run script"

echo
echo "3. s6 container_environment (only read by services using #!/usr/bin/with-contenv)"
seen3=0
for d in /var/run/s6/container_environment /run/s6/container_environment; do
    if [ -f "$d/$VAR" ]; then
        echo "   $d/$VAR = [$(cat "$d/$VAR")]"; seen3=1
    fi
done
[ "$seen3" -eq 0 ] && echo "   not present in either envdir"

echo
echo "4. the running process (the only stage that decides behaviour)"
if [ -z "$TARGET" ]; then
    echo "   no target given; pass a process name or pid as \$2"
else
    # Prefer an exact process-name match. A -f substring match picks up this script's own shell
    # (its command line contains the name you searched for), which produces confusing noise.
    if [ -d "/proc/$TARGET" ]; then
        pids="$TARGET"
    else
        pids=$(pgrep -x "$TARGET" 2> /dev/null | head -3)
        [ -z "$pids" ] && pids=$(pgrep -f "$TARGET" 2> /dev/null | grep -vE "^($$|$PPID)$" | head -3)
    fi
    if [ -z "$pids" ]; then
        echo "   no process matching '$TARGET'"
    else
        for pid in $pids; do
            comm=$(tr -d '\0' < "/proc/$pid/comm" 2> /dev/null)
            val=$(tr '\0' '\n' < "/proc/$pid/environ" 2> /dev/null | sed -n "s/^${VAR}=//p")
            if [ -n "$val" ]; then
                echo "   pid=$pid ($comm): ${VAR}=[$val]"
            else
                echo "   pid=$pid ($comm): ${VAR} NOT SET"
                # Naming the shebang is usually the whole answer.
                for d in /etc/s6-overlay/s6-rc.d /etc/services.d; do
                    while IFS= read -r rs; do
                        if grep -qiE "exec .*${comm}|${comm}" "$rs" 2> /dev/null; then
                            echo "     its service $rs starts: $(head -1 "$rs")"
                            head -1 "$rs" | grep -q with-contenv \
                                && echo "     -> uses with-contenv, so stage 3 WOULD reach it" \
                                || echo "     -> NOT with-contenv, so stage 3 can never reach it"
                            break 2
                        fi
                    done < <(find "$d" -name run -type f 2> /dev/null)
                done
            fi
            # What it was actually launched with beats any theory about its environment.
            tr '\0' '\n' < "/proc/$pid/cmdline" 2> /dev/null | tail -n +2 |
                grep -iE "res|screen|${VAR}" | head -3 | sed 's/^/     argv: /'
        done
    fi
fi

echo
echo "== reading the result =="
echo "  present at 4              -> the value reached the process; the bug is elsewhere"
echo "  at 1+2 but not 4          -> service started before injection, or reads a different name"
echo "  at 1+3 but not 2 or 4     -> classic silent no-op: wrong mechanism for this service"
echo "  at 1 only                 -> option name does not match any env var a service reads"
