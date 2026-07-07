#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail
mkdir -p "$HOME/.claude"

CLAUDE_DESKTOP_COMMAND_FILE="/tmp/claude-desktop-command"
DEFAULT_CLAUDE_DESKTOP_COMMAND='claude-desktop --no-sandbox --disable-dev-shm-usage --password-store=gnome-libsecret'
printf '%s\n' "$DEFAULT_CLAUDE_DESKTOP_COMMAND" > "$CLAUDE_DESKTOP_COMMAND_FILE"

if bashio::config.true 'install_headroom'; then
    if command -v headroom &> /dev/null; then
        # headroom "wrap" only supports coding-agent CLIs (claude|codex|cursor|...) and is
        # invalid for the Claude Desktop Electron app, so route the launch through headroom's
        # standalone compression proxy instead: start "headroom proxy" and point Claude Desktop
        # at it via ANTHROPIC_BASE_URL.
        #
        # NOTE: Claude Desktop currently force-overrides ANTHROPIC_BASE_URL to the production
        # endpoint (headroom #869), so compression only actually engages once upstream adds
        # Desktop support. Until then the app still launches normally, and the autostart falls
        # back to a plain launch if this command fails.
        HEADROOM_PROXY_PORT="8787"
        bashio::log.info "headroom $(headroom --version 2> /dev/null || true) available; launching Claude Desktop through the headroom proxy on 127.0.0.1:${HEADROOM_PROXY_PORT} (transparent compression pending Claude Desktop support, headroom #869)"
        printf '%s\n' "headroom proxy --port ${HEADROOM_PROXY_PORT} > /tmp/headroom-proxy.log 2>&1 & ANTHROPIC_BASE_URL=http://127.0.0.1:${HEADROOM_PROXY_PORT} ${DEFAULT_CLAUDE_DESKTOP_COMMAND}" > "$CLAUDE_DESKTOP_COMMAND_FILE"
    else
        bashio::log.warning "headroom is not available"
    fi
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
        curl --connect-timeout 10 --max-time 60 -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash || bashio::log.warning "caveman install failed (offline?)"
    fi
else
    bashio::log.info "Disabling caveman Claude Code plugin"
    find "$HOME/.claude" -maxdepth 4 -iname '*caveman*' -exec rm -rf {} + 2> /dev/null || true
fi
