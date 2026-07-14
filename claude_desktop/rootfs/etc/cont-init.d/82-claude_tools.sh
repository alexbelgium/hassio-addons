#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

PUID="$(if bashio::config.has_value 'PUID'; then bashio::config 'PUID'; else echo '0'; fi)"
PGID="$(if bashio::config.has_value 'PGID'; then bashio::config 'PGID'; else echo '0'; fi)"
mkdir -p "$HOME/.claude"

CLAUDE_DESKTOP_COMMAND_FILE="/tmp/claude-desktop-command"
DEFAULT_CLAUDE_DESKTOP_COMMAND='claude-desktop --no-sandbox --disable-dev-shm-usage --password-store=gnome-libsecret'
printf '%s\n' "$DEFAULT_CLAUDE_DESKTOP_COMMAND" > "$CLAUDE_DESKTOP_COMMAND_FILE"

# headroom's "wrap"/proxy routing works by setting ANTHROPIC_BASE_URL, which the Claude Desktop
# Electron app force-overrides to the production endpoint (headroom #869), so transparent
# compression cannot be applied to the desktop launch. The integration that does work with
# Claude Desktop is headroom's MCP server, which exposes the headroom_compress/headroom_retrieve/
# headroom_stats tools inside the app.
#
# Register the add-on-managed MCP servers (headroom, tokensave, homeassistant) in both Claude
# Desktop's config and Claude Code's user config (used by Desktop cowork/dispatch sessions).
# The merge is idempotent, preserves any other MCP servers, never overwrites a user-customized
# entry with a different command, and removes only add-on-managed entries when disabled.
CLAUDE_DESKTOP_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
CLAUDE_CODE_CONFIG="$HOME/.claude.json"

HEADROOM_ENABLED=false
if bashio::config.true 'install_headroom'; then
    if command -v headroom &> /dev/null; then
        HEADROOM_ENABLED=true
        bashio::log.info "headroom $(headroom --version 2> /dev/null || true) available; registering the headroom MCP server"
    else
        bashio::log.warning "headroom is not available"
    fi
fi

TOKENSAVE_ENABLED=false
if bashio::config.true 'install_tokensave'; then
    if command -v tokensave &> /dev/null; then
        TOKENSAVE_ENABLED=true
        bashio::log.info "tokensave $(tokensave --version 2> /dev/null || true) available; registering the tokensave MCP server"
    else
        bashio::log.warning "tokensave is not available"
    fi
fi

HA_MCP_ENABLED=false
HA_MCP_URL=""
HA_MCP_TOKEN=""
if bashio::config.true 'enable_ha_mcp'; then
    HA_MCP_URL="$(bashio::config 'ha_mcp_url' 'http://homeassistant:8123/mcp_server/sse')"
    if bashio::config.has_value 'ha_mcp_token'; then
        HA_MCP_TOKEN="$(bashio::config 'ha_mcp_token')"
    fi
    if [ -z "$HA_MCP_TOKEN" ]; then
        bashio::log.warning "enable_ha_mcp is on but ha_mcp_token is empty; set a Home Assistant long-lived access token (Profile -> Security) and enable the 'Model Context Protocol Server' integration"
    elif ! command -v mcp-proxy &> /dev/null; then
        bashio::log.warning "mcp-proxy is not available; cannot register the Home Assistant MCP server"
    else
        HA_MCP_ENABLED=true
        bashio::log.info "Registering the Home Assistant MCP server (${HA_MCP_URL})"
    fi
fi

HEADROOM_ENABLED="$HEADROOM_ENABLED" HEADROOM_BIN="$(command -v headroom || echo headroom)" \
    TOKENSAVE_ENABLED="$TOKENSAVE_ENABLED" TOKENSAVE_BIN="/usr/local/bin/tokensave" \
    HA_MCP_ENABLED="$HA_MCP_ENABLED" HA_MCP_URL="$HA_MCP_URL" HA_MCP_TOKEN="$HA_MCP_TOKEN" \
    MCP_PROXY_BIN="$(command -v mcp-proxy || echo mcp-proxy)" \
    CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_CONFIG" CLAUDE_CODE_CONFIG="$CLAUDE_CODE_CONFIG" \
    python3 - <<'PY' || bashio::log.warning "Unable to update the MCP server registrations automatically"
import json
import os
from pathlib import Path

MANAGED_COMMANDS = {
    "headroom": {os.environ["HEADROOM_BIN"], "headroom"},
    "tokensave": {os.environ["TOKENSAVE_BIN"], "tokensave"},
    "homeassistant": {os.environ["MCP_PROXY_BIN"], "mcp-proxy"},
}

desired = {}
if os.environ["HEADROOM_ENABLED"] == "true":
    desired["headroom"] = {"command": os.environ["HEADROOM_BIN"], "args": ["mcp", "serve"]}
if os.environ["TOKENSAVE_ENABLED"] == "true":
    desired["tokensave"] = {"command": os.environ["TOKENSAVE_BIN"], "args": ["serve"]}
if os.environ["HA_MCP_ENABLED"] == "true":
    desired["homeassistant"] = {
        "command": os.environ["MCP_PROXY_BIN"],
        "args": [os.environ["HA_MCP_URL"]],
        "env": {"API_ACCESS_TOKEN": os.environ["HA_MCP_TOKEN"]},
    }

def is_managed(name, entry):
    return isinstance(entry, dict) and entry.get("command") in MANAGED_COMMANDS[name]

for config_var, stdio_type in (("CLAUDE_DESKTOP_CONFIG", False), ("CLAUDE_CODE_CONFIG", True)):
    path = Path(os.environ[config_var])
    try:
        data = json.loads(path.read_text()) if path.exists() else {}
        if not isinstance(data, dict):
            data = {}
    except Exception:
        if path.exists():
            path.rename(path.with_suffix(path.suffix + ".bak"))
        data = {}
    servers = data.get("mcpServers")
    if not isinstance(servers, dict):
        servers = {}
    changed = False
    for name in MANAGED_COMMANDS:
        existing = servers.get(name)
        if name in desired:
            entry = dict(desired[name])
            if stdio_type:
                entry["type"] = "stdio"
            if existing is None or is_managed(name, existing):
                if existing != entry:
                    servers[name] = entry
                    changed = True
        elif existing is not None and is_managed(name, existing):
            del servers[name]
            changed = True
    if not changed:
        continue
    if servers:
        data["mcpServers"] = servers
    else:
        data.pop("mcpServers", None)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")
PY

# Guide Claude to actually use the headroom compression tools so the MCP integration produces
# real savings (otherwise the tools sit unused and `headroom savings` stays empty). Managed,
# idempotent block appended to the user's global CLAUDE.md; removed when headroom is disabled.
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
HEADROOM_GUIDE_BEGIN="<!-- BEGIN headroom (managed by claude_desktop addon) -->"
if bashio::config.true 'install_headroom'; then
    mkdir -p "$(dirname "$CLAUDE_MD")"
    if ! { [ -f "$CLAUDE_MD" ] && grep -qF "$HEADROOM_GUIDE_BEGIN" "$CLAUDE_MD"; }; then
        bashio::log.info "Adding headroom usage guidance to CLAUDE.md"
        {
            [ -s "$CLAUDE_MD" ] && printf '\n'
            cat <<'MD'
<!-- BEGIN headroom (managed by claude_desktop addon) -->
## Headroom context compression

A local Headroom proxy (127.0.0.1:8787) backs the `headroom` MCP tools. To save context tokens:
when you produce or read a **large, structured** blob you will keep referring to — file listings,
search results, JSON/config dumps, big command outputs, roughly >500 tokens — call
`mcp__headroom__headroom_compress` on it and keep the returned compressed text + `hash` instead of
the raw content. Call `mcp__headroom__headroom_retrieve` with that hash when you need the full
original back. Skip compression for error/stack-trace output (Headroom deliberately protects it)
and for small or one-off content. Use `mcp__headroom__headroom_stats` to check savings.
<!-- END headroom (managed by claude_desktop addon) -->
MD
        } >> "$CLAUDE_MD"
    fi
elif [ -f "$CLAUDE_MD" ] && grep -qF "$HEADROOM_GUIDE_BEGIN" "$CLAUDE_MD"; then
    bashio::log.info "Removing headroom usage guidance from CLAUDE.md"
    CLAUDE_MD="$CLAUDE_MD" python3 - <<'PY' || bashio::log.warning "Unable to remove headroom guidance automatically"
import os
import re
from pathlib import Path

path = Path(os.environ["CLAUDE_MD"])
text = path.read_text()
pattern = re.compile(
    r"\n*<!-- BEGIN headroom \(managed by claude_desktop addon\) -->.*?"
    r"<!-- END headroom \(managed by claude_desktop addon\) -->\n?",
    re.DOTALL,
)
new = pattern.sub("", text)
if new != text:
    path.write_text(new)
PY
fi

if bashio::config.true 'install_rtk'; then
    if command -v rtk &> /dev/null; then
        if [ -f "$HOME/.claude/settings.json" ] && grep -q 'rtk hook claude' "$HOME/.claude/settings.json"; then
            bashio::log.info "rtk Claude Code hook already configured"
        else
            bashio::log.info "Configuring rtk Claude Code hook"
            RTK_NONINTERACTIVE=1 rtk init -g || bashio::log.warning "rtk global files configuration failed"
            python3 - <<'PY' || bashio::log.warning "Unable to configure rtk hook automatically"
import json
from pathlib import Path
path = Path.home() / ".claude" / "settings.json"
try:
    data = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    if path.exists():
        path.rename(path.with_suffix(path.suffix + ".bak"))
    data = {}
hooks = data.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
rtk_entry = {"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]}
if not any("rtk hook claude" in json.dumps(entry) for entry in pre if isinstance(entry, dict)):
    pre.append(rtk_entry)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2) + "\n")
PY
        fi
    else
        bashio::log.warning "rtk is not available"
    fi
elif [ -f "$HOME/.claude/settings.json" ]; then
    bashio::log.info "Removing the add-on-managed rtk Claude Code hook"
    python3 - <<'PY' || bashio::log.warning "Unable to remove rtk hook automatically"
import json
from pathlib import Path

path = Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text())
if not isinstance(data, dict):
    raise TypeError("Claude settings must contain a JSON object")

hooks = data.get("hooks")
if not isinstance(hooks, dict):
    raise SystemExit(0)

entries = hooks.get("PreToolUse")
if not isinstance(entries, list):
    raise SystemExit(0)

changed = False
filtered_entries = []
for entry in entries:
    if not isinstance(entry, dict) or entry.get("matcher") != "Bash":
        filtered_entries.append(entry)
        continue

    commands = entry.get("hooks")
    if not isinstance(commands, list):
        filtered_entries.append(entry)
        continue

    filtered_commands = [
        command
        for command in commands
        if not (
            isinstance(command, dict)
            and command.get("type") == "command"
            and command.get("command") == "rtk hook claude"
        )
    ]
    if len(filtered_commands) == len(commands):
        filtered_entries.append(entry)
        continue

    changed = True
    if filtered_commands:
        updated_entry = dict(entry)
        updated_entry["hooks"] = filtered_commands
        filtered_entries.append(updated_entry)

if changed:
    if filtered_entries:
        hooks["PreToolUse"] = filtered_entries
    else:
        hooks.pop("PreToolUse", None)
    if hooks:
        data["hooks"] = hooks
    else:
        data.pop("hooks", None)
    path.write_text(json.dumps(data, indent=2) + "\n")
PY
fi

if bashio::config.true 'install_caveman'; then
    if [ -d "$HOME/.claude/plugins/caveman" ] || find "$HOME/.claude" -maxdepth 4 -iname '*caveman*' -print -quit | grep -q .; then
        bashio::log.info "caveman Claude Code plugin already configured"
    else
        bashio::log.info "Installing caveman Claude Code plugin"
        curl --connect-timeout 10 --max-time 60 -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash >/dev/null || bashio::log.warning "caveman install failed (offline?)"
    fi
else
    bashio::log.info "Disabling caveman Claude Code plugin"
    find "$HOME/.claude" -maxdepth 4 -iname '*caveman*' -exec rm -rf {} + 2> /dev/null || true
fi

# Startup configuration runs as root, while Claude Desktop runs as abc. Return managed
# persistent files to the configured runtime UID/GID after all writes complete.
for managed_path in "$HOME/.claude" "$HOME/.claude.json" "$HOME/.config/Claude"; do
    if [ -e "$managed_path" ]; then
        chown -R -- "${PUID}:${PGID}" "$managed_path" || bashio::log.warning "Unable to set ownership on $managed_path"
    fi
done
