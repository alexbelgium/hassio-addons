#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail
mkdir -p "$HOME/.claude"

CLAUDE_DESKTOP_COMMAND_FILE="/tmp/claude-desktop-command"
DEFAULT_CLAUDE_DESKTOP_COMMAND='claude-desktop --no-sandbox --disable-dev-shm-usage --password-store=gnome-libsecret'
printf '%s\n' "$DEFAULT_CLAUDE_DESKTOP_COMMAND" > "$CLAUDE_DESKTOP_COMMAND_FILE"

# headroom's "wrap"/proxy routing works by setting ANTHROPIC_BASE_URL, which the Claude Desktop
# Electron app force-overrides to the production endpoint (headroom #869), so transparent
# compression cannot be applied to the desktop launch. The integration that does work with
# Claude Desktop is headroom's MCP server, which exposes the headroom_compress/headroom_retrieve/
# headroom_stats tools inside the app. Register it in Claude Desktop's MCP config, leaving the
# plain launch untouched. The merge is idempotent and preserves any other MCP servers.
CLAUDE_DESKTOP_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
if bashio::config.true 'install_headroom'; then
    if command -v headroom &> /dev/null; then
        bashio::log.info "headroom $(headroom --version 2> /dev/null || true) available; registering the headroom MCP server for Claude Desktop"
        HEADROOM_BIN="$(command -v headroom)" CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_CONFIG" python3 - <<'PY' || bashio::log.warning "Unable to register the headroom MCP server automatically"
import json
import os
from pathlib import Path

path = Path(os.environ["CLAUDE_DESKTOP_CONFIG"])
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
    data["mcpServers"] = servers
servers["headroom"] = {"command": os.environ.get("HEADROOM_BIN", "headroom"), "args": ["mcp", "serve"]}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2) + "\n")
PY
    else
        bashio::log.warning "headroom is not available"
    fi
elif [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
    bashio::log.info "Removing the headroom MCP server from Claude Desktop"
    CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_CONFIG" python3 - <<'PY' || bashio::log.warning "Unable to remove the headroom MCP server automatically"
import json
import os
from pathlib import Path

path = Path(os.environ["CLAUDE_DESKTOP_CONFIG"])
data = json.loads(path.read_text())
if isinstance(data, dict):
    servers = data.get("mcpServers")
    if isinstance(servers, dict) and servers.pop("headroom", None) is not None:
        if not servers:
            data.pop("mcpServers", None)
        path.write_text(json.dumps(data, indent=2) + "\n")
PY
fi

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
elif [ -f "$HOME/.claude/settings.json" ] && grep -q 'rtk' "$HOME/.claude/settings.json"; then
    bashio::log.info "Removing rtk Claude Code hook"
    python3 - <<'PY' || bashio::log.warning "Unable to remove rtk hook automatically"
import json
from pathlib import Path
path = Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text())
hooks = data.get("hooks", {})
for event, entries in list(hooks.items()):
    if isinstance(entries, list):
        hooks[event] = [entry for entry in entries if "rtk" not in json.dumps(entry)]
        if not hooks[event]:
            hooks.pop(event, None)
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
