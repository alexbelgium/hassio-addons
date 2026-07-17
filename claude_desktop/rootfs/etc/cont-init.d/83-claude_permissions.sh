#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

PERMISSION_MODE="$(bashio::config 'permission_mode')"
SETTINGS_PATH="$HOME/.claude/settings.json"

case "$PERMISSION_MODE" in
    strict | auto | bypass) ;;
    *)
        bashio::log.warning "Unknown permission_mode '${PERMISSION_MODE}'; falling back to strict"
        PERMISSION_MODE="strict"
        ;;
esac

# Managed-value semantics, matching the ANTHROPIC_BASE_URL handling in 82-claude_tools.sh:
# auto/bypass set permissions.defaultMode to the add-on-managed value, and strict removes it
# only while it still holds one of those managed values — a defaultMode the user set by hand
# is never deleted. Ownership of the written file is reconciled by 84-claude_runtime_ownership.sh.
mkdir -p "$(dirname "$SETTINGS_PATH")"
PERMISSION_MODE="$PERMISSION_MODE" SETTINGS_PATH="$SETTINGS_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path

MANAGED_VALUES = {"auto", "bypassPermissions"}

mode = os.environ["PERMISSION_MODE"]
settings_path = Path(os.environ["SETTINGS_PATH"])

try:
    settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
except (OSError, json.JSONDecodeError):
    if settings_path.exists():
        settings_path.rename(settings_path.with_suffix(settings_path.suffix + ".bak"))
    settings = {}
if not isinstance(settings, dict):
    settings = {}

permissions = settings.get("permissions")
if not isinstance(permissions, dict):
    permissions = {}

if mode == "strict":
    if permissions.get("defaultMode") in MANAGED_VALUES:
        permissions.pop("defaultMode")
else:
    permissions["defaultMode"] = "auto" if mode == "auto" else "bypassPermissions"

if permissions:
    settings["permissions"] = permissions
else:
    settings.pop("permissions", None)

settings_path.write_text(json.dumps(settings, indent=2) + "\n")
settings_path.chmod(0o600)
PY

# Drop the state file older add-on versions used to remember the pre-add-on defaultMode.
rm -f "$HOME/.claude/.addon-permission-mode.json"

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
