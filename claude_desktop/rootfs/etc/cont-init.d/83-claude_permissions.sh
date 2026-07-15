#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

PUID="$(if bashio::config.has_value 'PUID'; then bashio::config 'PUID'; else echo '0'; fi)"
PGID="$(if bashio::config.has_value 'PGID'; then bashio::config 'PGID'; else echo '0'; fi)"
PERMISSION_MODE="$(bashio::config 'permission_mode')"
SETTINGS_PATH="$HOME/.claude/settings.json"
STATE_PATH="$HOME/.claude/.addon-permission-mode.json"

case "$PERMISSION_MODE" in
    strict|auto|bypass) ;;
    *)
        bashio::log.warning "Unknown permission_mode '${PERMISSION_MODE}'; falling back to strict"
        PERMISSION_MODE="strict"
        ;;
esac

mkdir -p "$(dirname "$SETTINGS_PATH")"
PERMISSION_MODE="$PERMISSION_MODE" SETTINGS_PATH="$SETTINGS_PATH" STATE_PATH="$STATE_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path

mode = os.environ["PERMISSION_MODE"]
settings_path = Path(os.environ["SETTINGS_PATH"])
state_path = Path(os.environ["STATE_PATH"])

try:
    settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
except (OSError, json.JSONDecodeError):
    if settings_path.exists():
        settings_path.rename(settings_path.with_suffix(settings_path.suffix + ".bak"))
    settings = {}
if not isinstance(settings, dict):
    settings = {}

try:
    state = json.loads(state_path.read_text()) if state_path.exists() else None
except (OSError, json.JSONDecodeError):
    state = None
if not isinstance(state, dict):
    state = None

permissions = settings.get("permissions")
if not isinstance(permissions, dict):
    permissions = {}

if mode == "strict":
    # Restore the value that existed before the add-on first managed this setting.
    if state is not None:
        if state.get("previous_exists"):
            permissions["defaultMode"] = state.get("previous_value")
        else:
            permissions.pop("defaultMode", None)
        state_path.unlink(missing_ok=True)
else:
    if state is None:
        state = {
            "previous_exists": "defaultMode" in permissions,
            "previous_value": permissions.get("defaultMode"),
        }
        state_path.write_text(json.dumps(state, indent=2) + "\n")
        state_path.chmod(0o600)
    permissions["defaultMode"] = "auto" if mode == "auto" else "bypassPermissions"

if permissions:
    settings["permissions"] = permissions
else:
    settings.pop("permissions", None)

settings_path.write_text(json.dumps(settings, indent=2) + "\n")
settings_path.chmod(0o600)
PY

case "$PERMISSION_MODE" in
    strict)
        bashio::log.info "Claude Code permission mode: strict (normal prompts)"
        ;;
    auto)
        bashio::log.info "Claude Code permission mode: auto (safe actions approved automatically)"
        ;;
    bypass)
        bashio::log.warning "Claude Code permission mode: bypass (permission checks disabled for mounted data and available tools)"
        ;;
esac

chown -- "${PUID}:${PGID}" "$SETTINGS_PATH" 2> /dev/null || true
if [ -e "$STATE_PATH" ]; then
    chown -- "${PUID}:${PGID}" "$STATE_PATH" 2> /dev/null || true
fi
