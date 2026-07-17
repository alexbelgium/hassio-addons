#!/usr/bin/with-contenv bashio
# Diagnose installation, registration, routing, indexing, permissions, and recorded savings without
# printing MCP environment values (which may contain the Home Assistant access token).
# shellcheck shell=bash
set +e
set -o pipefail
export NO_COLOR=1
export PATH="/lsiopy/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

section() {
    printf '\n=== %s ===\n' "$1"
}

section "Installed binaries"
for tool in claude claude-desktop headroom rtk tokensave git gh rg jq shellcheck yamllint hadolint actionlint; do
    resolved="$(command -v "$tool" 2> /dev/null || true)"
    if [ -n "$resolved" ]; then
        printf '%-16s %s\n' "$tool" "$resolved"
    else
        printf '%-16s %s\n' "$tool" "MISSING"
    fi
done

section "Configured switches"
for option in permission_mode install_headroom headroom_wrap_claude_code expose_headroom_dashboard install_rtk install_tokensave install_caveman enable_tools_health_report; do
    printf '%-30s %s\n' "$option" "$(bashio::config "$option")"
done

section "Runtime identity"
printf '%-30s %s\n' "configured PUID:PGID" "$(bashio::config 'PUID'):$(bashio::config 'PGID')"
printf '%-30s %s\n' "effective abc UID:GID" "$(id -u abc):$(id -g abc)"
printf '%-30s %s\n' "current process UID:GID" "$(id -u):$(id -g)"
if [ "$(bashio::config 'permission_mode')" = "bypass" ]; then
    if [ "$(id -u abc)" -eq 0 ]; then
        echo "bypass runtime: ERROR - Claude Code will reject bypass permissions while abc is root"
    else
        echo "bypass runtime: OK - Claude Desktop and Cowork run as a non-root UID"
    fi
fi

section "Claude Code permission state"
python3 - <<'PY'
import json
from pathlib import Path

path = Path.home() / ".claude/settings.json"
try:
    data = json.loads(path.read_text())
except FileNotFoundError:
    print("settings: MISSING")
except Exception as exc:
    print(f"settings: INVALID: {exc}")
else:
    permissions = data.get("permissions", {})
    if isinstance(permissions, dict):
        print(f"permissions.defaultMode: {permissions.get('defaultMode', '<upstream default>')}")
    else:
        print("permissions: INVALID")
PY

section "MCP registrations (environment values redacted)"
python3 - <<'PY'
import json
from pathlib import Path

paths = [
    Path.home() / ".claude.json",
    Path.home() / ".config/Claude/claude_desktop_config.json",
]
for path in paths:
    print(path)
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        print("  MISSING")
        continue
    except Exception as exc:
        print(f"  INVALID: {exc}")
        continue
    servers = data.get("mcpServers", {})
    if not isinstance(servers, dict) or not servers:
        print("  no MCP servers")
        continue
    for name, spec in sorted(servers.items()):
        if not isinstance(spec, dict):
            print(f"  {name}: invalid entry")
            continue
        command = spec.get("command", "?")
        args = spec.get("args", [])
        server_type = spec.get("type", "")
        suffix = f" type={server_type}" if server_type else ""
        print(f"  {name}: {command} {args}{suffix}")
        if spec.get("env"):
            print("    env: <redacted>")
PY

section "Claude Code hooks"
python3 - <<'PY'
import json
from pathlib import Path

path = Path.home() / ".claude/settings.json"
try:
    data = json.loads(path.read_text())
except FileNotFoundError:
    print("MISSING")
    raise SystemExit(0)
except Exception as exc:
    print(f"INVALID: {exc}")
    raise SystemExit(0)

hooks = data.get("hooks", {})
if not isinstance(hooks, dict) or not hooks:
    print("no hooks")
    raise SystemExit(0)
for event, entries in hooks.items():
    print(event)
    if not isinstance(entries, list):
        print("  invalid entries")
        continue
    for entry in entries:
        matcher = entry.get("matcher", "*") if isinstance(entry, dict) else "?"
        commands = entry.get("hooks", []) if isinstance(entry, dict) else []
        rendered = []
        for command in commands if isinstance(commands, list) else []:
            if isinstance(command, dict):
                rendered.append(" ".join([str(command.get("command", "?")), *map(str, command.get("args", []))]))
        print(f"  matcher={matcher}: {', '.join(rendered) or 'no command'}")
PY

section "Headroom"
if bashio::config.true 'install_headroom'; then
    curl -fsS --max-time 2 http://127.0.0.1:8787/health && echo || echo "proxy health: FAILED"
    headroom mcp status || true
    headroom savings || true
else
    echo "disabled"
fi

section "RTK"
if bashio::config.true 'install_rtk'; then
    rtk gain || true
else
    echo "disabled"
fi

section "TokenSave"
if bashio::config.true 'install_tokensave'; then
    tokensave doctor --agent claude || true
    tokensave gain --all --range 30d || true
    # Capture before looping — see the matching comment in 82-claude_tools.sh: feeding the
    # loop straight from `< <(bashio::config ...)` yields an empty list under errexit.
    TOKENSAVE_PROJECT_PATHS="$(bashio::config 'tokensave_project_paths')"
    while IFS= read -r configured_path || [ -n "$configured_path" ]; do
        if [ -z "$configured_path" ] || [ "$configured_path" = "null" ]; then
            continue
        fi
        repo_root="$(s6-setuidgid abc env HOME="$HOME" git -c safe.directory='*' -C "$configured_path" rev-parse --show-toplevel 2> /dev/null || true)"
        if [ -z "$repo_root" ]; then
            echo "${configured_path}: not a Git repository"
        elif [ -f "$repo_root/.tokensave/tokensave.db" ]; then
            s6-setuidgid abc env HOME="$HOME" tokensave status "$repo_root" --short || true
        else
            echo "${repo_root}: NOT INITIALIZED"
        fi
    done <<< "$TOKENSAVE_PROJECT_PATHS"
else
    echo "disabled"
fi

section "Claude routing"
printf 'PATH claude: %s\n' "$(command -v claude 2> /dev/null || true)"
printf 'real claude: %s\n' "$([ -x /usr/bin/claude ] && echo /usr/bin/claude || echo MISSING)"
if bashio::config.true 'headroom_wrap_claude_code'; then
    echo "PATH-based Claude Code launches are configured for Headroom wrapping."
else
    echo "Claude Code Headroom wrapping is disabled; Headroom remains available through MCP."
fi
