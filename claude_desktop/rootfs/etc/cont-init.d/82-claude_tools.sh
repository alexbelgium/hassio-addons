#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

mkdir -p "$HOME/.claude"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

run_as_runtime_user() {
    s6-setuidgid abc env HOME="$HOME" "$@"
}

# Managed, idempotent guidance block in the user's global CLAUDE.md, delimited by
# "<!-- BEGIN/END <name> (managed by claude_desktop addon) -->" markers. `add` appends the
# block (body on stdin) unless the marker is already present; `remove` strips the whole
# block, surrounding blank padding included, and leaves everything else untouched.
manage_claude_md_block() {
    local name="$1" action="$2"
    local begin="<!-- BEGIN ${name} (managed by claude_desktop addon) -->"
    if [ "$action" = "add" ]; then
        if ! { [ -f "$CLAUDE_MD" ] && grep -qF "$begin" "$CLAUDE_MD"; }; then
            bashio::log.info "Adding ${name} guidance to CLAUDE.md"
            mkdir -p "$(dirname "$CLAUDE_MD")"
            {
                [ -s "$CLAUDE_MD" ] && printf '\n'
                printf '%s\n' "$begin"
                cat
                printf '%s\n' "<!-- END ${name} (managed by claude_desktop addon) -->"
            } >> "$CLAUDE_MD"
        fi
    elif [ -f "$CLAUDE_MD" ] && grep -qF "$begin" "$CLAUDE_MD"; then
        bashio::log.info "Removing ${name} guidance from CLAUDE.md"
        CLAUDE_MD="$CLAUDE_MD" BLOCK_NAME="$name" python3 - <<'PY' || bashio::log.warning "Unable to remove the ${name} guidance automatically"
import os
import re
from pathlib import Path

path = Path(os.environ["CLAUDE_MD"])
name = re.escape(os.environ["BLOCK_NAME"])
text = path.read_text(encoding="utf-8")
pattern = re.compile(
    rf"\n*<!-- BEGIN {name} \(managed by claude_desktop addon\) -->.*?"
    rf"<!-- END {name} \(managed by claude_desktop addon\) -->\n?",
    re.DOTALL,
)
new = pattern.sub("", text)
if new != text:
    path.write_text(new, encoding="utf-8")
PY
    fi
}

# Managed hook entry in ~/.claude/settings.json (settings hooks apply to terminal, cowork,
# dispatch and cron sessions alike). The managed command is stripped everywhere first and
# re-appended when adding, so one pass handles removal, de-duplication, and matcher migration
# on upgrades; hooks owned by other tools (e.g. tokensave's own entries) are preserved, and
# the final text comparison keeps the write idempotent across boots.
manage_settings_hook() {
    # manage_settings_hook <event> <matcher> <command> <add|remove>
    HOOK_EVENT="$1" HOOK_MATCHER="$2" HOOK_COMMAND="$3" HOOK_ACTION="$4" \
        python3 - <<'PY' || bashio::log.warning "Unable to update the $1 hook for '$3'"
import json
import os
from pathlib import Path

event = os.environ["HOOK_EVENT"]
matcher = os.environ["HOOK_MATCHER"]
command = os.environ["HOOK_COMMAND"]
action = os.environ["HOOK_ACTION"]

path = Path.home() / ".claude" / "settings.json"
original = path.read_text() if path.exists() else None
if original is None and action != "add":
    raise SystemExit(0)
try:
    data = json.loads(original) if original is not None else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    if action != "add":
        raise SystemExit(0)
    path.rename(path.with_suffix(path.suffix + ".bak"))
    original = None
    data = {}

hooks = data.get("hooks") if isinstance(data.get("hooks"), dict) else {}
entries = hooks.get(event) if isinstance(hooks.get(event), list) else []

filtered = []
for entry in entries:
    if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
        filtered.append(entry)
        continue
    kept = [
        item
        for item in entry["hooks"]
        if not (isinstance(item, dict) and item.get("command") == command)
    ]
    if len(kept) != len(entry["hooks"]):
        if not kept:
            continue
        entry = dict(entry)
        entry["hooks"] = kept
    filtered.append(entry)
entries = filtered

if action == "add":
    entries.append({"matcher": matcher, "hooks": [{"type": "command", "command": command}]})

if entries:
    hooks[event] = entries
else:
    hooks.pop(event, None)
if hooks:
    data["hooks"] = hooks
else:
    data.pop("hooks", None)

serialized = json.dumps(data, indent=2) + "\n"
if serialized != original:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(serialized)
PY
}

# Headroom's proxy routing works by setting ANTHROPIC_BASE_URL, which the Claude Desktop
# Electron app force-overrides to the production endpoint (headroom #869). Desktop therefore
# uses Headroom's MCP tools. Claude Code launches that resolve `claude` through PATH use the
# add-on's /usr/local/bin/claude wrapper and can be transparently proxied when enabled.
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
        bashio::log.info "tokensave $(tokensave --version 2> /dev/null || true) available; configuring the complete Claude Code integration"
        # The upstream installer adds the MCP entry, PreToolUse/UserPromptSubmit/Stop hooks,
        # MCP permissions, global CLAUDE.md rules, and the global post-commit/checkout sync hook.
        run_as_runtime_user tokensave install --agent claude --git-hook yes \
            || bashio::log.warning "tokensave Claude Code integration setup failed"
    else
        bashio::log.warning "tokensave is not available"
    fi
elif command -v tokensave &> /dev/null; then
    bashio::log.info "Removing the tokensave Claude Code integration"
    run_as_runtime_user tokensave uninstall --agent claude \
        || bashio::log.warning "tokensave Claude Code integration removal failed"
fi

# Initialize or incrementally sync only explicitly configured repositories. TokenSave deliberately
# requires one-time per-project opt-in; an empty list therefore has no startup or storage cost.
# Runs before the MCP registration merge below on purpose: a first-time `tokensave init` also
# rewrites ~/.claude.json itself (at default permissions), and the merge afterwards reconciles
# the managed entries and re-tightens the file mode around the stored HA token.
if $TOKENSAVE_ENABLED; then
    declare -A TOKENSAVE_REPOS_SEEN=()
    # Capture the list BEFORE looping: bashio::config's internals trip the errexit that
    # process substitution inherits from the bashio wrapper (a `read -d ''` that always
    # returns non-zero), so `done < <(bashio::config ...)` silently fed the loop an EMPTY
    # list — the startup index/sync never ran. Command substitution runs without errexit
    # (inherit_errexit is off), making this form reliable. bashio::config prints list
    # entries one per line, without a trailing newline and as "null" when the key is absent
    # (bashio::config.array only exists in the repo's standalone bashio, not the real one
    # here); the `|| [ -n ... ]` test keeps the final unterminated record in the loop.
    TOKENSAVE_PROJECT_PATHS="$(bashio::config 'tokensave_project_paths')"
    while IFS= read -r configured_path || [ -n "$configured_path" ]; do
        # Trim surrounding whitespace while preserving spaces inside paths.
        configured_path="${configured_path#"${configured_path%%[![:space:]]*}"}"
        configured_path="${configured_path%"${configured_path##*[![:space:]]}"}"
        if [ -z "$configured_path" ] || [ "$configured_path" = "null" ]; then
            continue
        fi

        case "$configured_path" in
            /*) ;;
            *)
                bashio::log.warning "Skipping non-absolute tokensave_project_paths entry: ${configured_path}"
                continue
                ;;
        esac
        if [ ! -d "$configured_path" ]; then
            bashio::log.warning "Skipping missing TokenSave project path: ${configured_path}"
            continue
        fi

        # The one-shot safe.directory override is used only to discover the repository root.
        repo_root="$(run_as_runtime_user git -c safe.directory='*' -C "$configured_path" rev-parse --show-toplevel 2> /dev/null || true)"
        if [ -z "$repo_root" ] || [ "$repo_root" = "/" ]; then
            bashio::log.warning "Skipping TokenSave path that is not a supported Git repository: ${configured_path}"
            continue
        fi
        if [[ -n "${TOKENSAVE_REPOS_SEEN[$repo_root]:-}" ]]; then
            continue
        fi
        TOKENSAVE_REPOS_SEEN[$repo_root]=1

        # Persist the resolved root in the runtime user's Git config so the sync/init below,
        # tokensave's git hooks, and Claude sessions all pass Git's dubious-ownership check.
        if ! run_as_runtime_user git config --global --get-all safe.directory \
            | grep -Fxq -- "$repo_root"; then
            run_as_runtime_user git config --global --add safe.directory "$repo_root"
            bashio::log.info "Marked TokenSave repository as safe for Git: ${repo_root}"
        fi

        bashio::log.info "Preparing TokenSave index: ${repo_root}"
        # Prepare the per-repo semantic graph defensively so a hard add-on stop or storage
        # hiccup can never leave a broken index that fails every subsequent boot:
        #   * a startup-scoped flock serializes against an overlapping restart (and any git
        #     post-commit/checkout sync hook that fires mid-boot); waits up to 60s for the
        #     other writer to finish rather than silently skipping, since a held lock clears
        #     itself the moment its holder exits or dies (the kernel releases flock on exit);
        #   * an existing index is refreshed with a cheap incremental `sync`, retried a few
        #     times because SQLITE_BUSY under lock contention is transient, not corruption;
        #   * quarantine is reserved for sync failures whose stderr actually names database
        #     corruption (SQLite's own "malformed"/"not a database"/"disk image" wording) or
        #     a half-written index from an interrupted `init` (sentinel-flagged). Any other
        #     failure (permissions, disk full, missing binary, ...) leaves the existing index
        #     untouched and simply retries on the next start — corruption should self-heal,
        #     a transient environment problem should not nuke a healthy graph;
        #   * `init` is bracketed by a sentinel file so an interrupted full build is detected
        #     as incomplete on the next start and rebuilt rather than trusted.
        # All file operations run as the abc runtime user because the repo `.tokensave`
        # directory is not covered by the startup ownership pass.
        # shellcheck disable=SC2016  # single-quoted on purpose: $1/$db/etc. expand in the abc shell
        run_as_runtime_user bash -c '
            set -o pipefail
            repo_root="$1"
            ts_dir="$repo_root/.tokensave"
            db="$ts_dir/tokensave.db"
            lock="$ts_dir/.startup.lock"
            initflag="$ts_dir/.init-incomplete"
            mkdir -p "$ts_dir"
            exec 9>"$lock"
            if ! flock -w 60 9; then
                echo "TokenSave: index still locked for $repo_root after 60s; skipping startup sync" >&2
                exit 0
            fi
            is_corruption() {
                printf "%s" "$1" | grep -qiE "malformed|not a database|file is encrypted|disk image|database.*corrupt"
            }
            quarantine() {
                stamp="$(date +%Y%m%d-%H%M%S)"
                bdir="$ts_dir/corrupt-$stamp"
                mkdir -p "$bdir"
                for f in "$db" "$db-wal" "$db-shm"; do
                    [ -e "$f" ] && mv -f "$f" "$bdir/" 2>/dev/null || true
                done
                echo "TokenSave: quarantined suspect index to $bdir" >&2
            }
            if [ -f "$db" ] && [ ! -f "$initflag" ]; then
                attempt=1
                while :; do
                    sync_err="$(tokensave sync "$repo_root" 2>&1 1>/dev/null)" && exit 0
                    [ "$attempt" -ge 3 ] && break
                    echo "TokenSave: sync attempt $attempt failed for $repo_root; retrying" >&2
                    attempt=$((attempt + 1))
                    sleep 2
                done
                if is_corruption "$sync_err"; then
                    echo "TokenSave: sync failed after retries for $repo_root (corruption detected); rebuilding index" >&2
                    quarantine
                else
                    echo "TokenSave: sync failed after retries for $repo_root (no corruption signature); leaving index in place, will retry next start" >&2
                    echo "TokenSave: last sync error: $sync_err" >&2
                    exit 1
                fi
            elif [ -f "$db" ]; then
                echo "TokenSave: previous init did not finish for $repo_root; rebuilding index" >&2
                quarantine
            fi
            : > "$initflag"
            tokensave init "$repo_root" && { rm -f "$initflag"; exit 0; }
            echo "TokenSave: init failed for $repo_root; will retry on next start" >&2
            exit 1
        ' _ "$repo_root" \
            || bashio::log.warning "TokenSave preparation failed for ${repo_root}"
    done <<< "$TOKENSAVE_PROJECT_PATHS"
fi

HA_MCP_ENABLED=false
HA_MCP_URL=""
HA_MCP_TOKEN=""
if bashio::config.true 'enable_ha_mcp'; then
    HA_MCP_URL="$(bashio::config 'ha_mcp_url' 'http://homeassistant:8123/api/mcp')"
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
    HEADROOM_HF_HOME="${HOME}/.headroom/hf" \
    TOKENSAVE_ENABLED="$TOKENSAVE_ENABLED" TOKENSAVE_BIN="$(command -v tokensave || echo tokensave)" \
    HA_MCP_ENABLED="$HA_MCP_ENABLED" HA_MCP_URL="$HA_MCP_URL" HA_MCP_TOKEN="$HA_MCP_TOKEN" \
    MCP_PROXY_BIN="$(command -v mcp-proxy || echo mcp-proxy)" \
    CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_CONFIG" CLAUDE_CODE_CONFIG="$CLAUDE_CODE_CONFIG" \
    python3 - <<'PY' || bashio::log.warning "Unable to update the MCP server registrations automatically"
import json
import os
from pathlib import Path

MANAGED_BASENAMES = {
    "headroom": "headroom",
    "tokensave": "tokensave",
    "homeassistant": "mcp-proxy",
}

desired = {}
if os.environ["HEADROOM_ENABLED"] == "true":
    desired["headroom"] = {
        "command": os.environ["HEADROOM_BIN"],
        "args": ["mcp", "serve", "--proxy-url", "http://127.0.0.1:8787"],
        # The MCP server is a separate process from the svc-headroom proxy longrun and does
        # not inherit its HF_HOME export, so Kompress falls back to the default (tmpfs, wiped
        # every restart) cache dir, never finds the model, and silently no-ops every
        # compression request. Point it at the same persistent cache the proxy warms.
        "env": {"HF_HOME": os.environ["HEADROOM_HF_HOME"]},
    }
if os.environ["TOKENSAVE_ENABLED"] == "true":
    desired["tokensave"] = {"command": os.environ["TOKENSAVE_BIN"], "args": ["serve"]}
if os.environ["HA_MCP_ENABLED"] == "true":
    # Home Assistant's MCP Server integration speaks stateless Streamable HTTP on /api/mcp;
    # mcp-proxy defaults to SSE, so the transport flags are required.
    desired["homeassistant"] = {
        "command": os.environ["MCP_PROXY_BIN"],
        "args": ["--transport=streamablehttp", "--stateless", os.environ["HA_MCP_URL"]],
        "env": {"API_ACCESS_TOKEN": os.environ["HA_MCP_TOKEN"]},
    }

# An entry is add-on-managed when its command is one of our binaries living outside the
# persistent home. Matching on the basename (rather than the exact path recorded at write
# time) keeps entries updatable when a base-image upgrade moves the binary, while commands
# under $HOME stay untouched because those are user-installed.
HOME_PREFIX = os.path.expanduser("~") + os.sep


def is_managed(name, entry):
    if not isinstance(entry, dict):
        return False
    command = entry.get("command")
    if not isinstance(command, str) or command.startswith(HOME_PREFIX):
        return False
    return os.path.basename(command) == MANAGED_BASENAMES[name]


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
    for name in MANAGED_BASENAMES:
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
    if changed:
        if servers:
            data["mcpServers"] = servers
        else:
            data.pop("mcpServers", None)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, indent=2) + "\n")
    # The Home Assistant long-lived access token is stored here in clear text. Enforced even
    # on no-change boots because tokensave's own writes can recreate the file with default
    # permissions between merges.
    if path.exists():
        path.chmod(0o600)
PY

# Guide Claude to actually use the Headroom compression tools so the MCP integration produces
# real savings when transparent proxying is unavailable.
if $HEADROOM_ENABLED; then
    manage_claude_md_block headroom add <<'MD'
## Headroom context compression

A local Headroom proxy (127.0.0.1:8787) backs the `headroom` MCP tools. To save context tokens:
when you produce or read a **large, structured** blob you will keep referring to — file listings,
search results, JSON/config dumps, big command outputs, roughly >500 tokens — call
`mcp__headroom__headroom_compress` on it and keep the returned compressed text + `hash` instead of
the raw content. Call `mcp__headroom__headroom_retrieve` with that hash when you need the full
original back. Skip compression for error/stack-trace output (Headroom deliberately protects it)
and for small or one-off content. Use `mcp__headroom__headroom_stats` to check savings.
MD
else
    manage_claude_md_block headroom remove
fi

# Route every Claude Code session through the Headroom proxy via the `env` block in the user's
# ~/.claude/settings.json. Claude Code writes settings `env` entries into the process
# environment at startup, replacing inherited values — this is the only supported way to reach
# Desktop cowork/local-agent-mode sessions, which spawn the bundled CLI at an absolute path
# (bypassing the PATH wrapper) with ANTHROPIC_BASE_URL pinned to the production endpoint
# (headroom #869). Managed-value semantics: only set or remove the variable when it is absent
# or already equals the add-on-managed proxy URL, so a user-customized endpoint is never
# clobbered. The svc-headroom longrun is s6-supervised, so a crashed proxy restarts within
# seconds; the terminal wrapper's per-launch health check remains as an extra safety net.
if $HEADROOM_ENABLED && bashio::config.true 'headroom_wrap_claude_code'; then
    HEADROOM_ROUTE_ACTION="add"
else
    HEADROOM_ROUTE_ACTION="remove"
fi
HEADROOM_ROUTE_ACTION="$HEADROOM_ROUTE_ACTION" python3 - <<'PY' || bashio::log.warning "Unable to manage the Claude Code proxy routing env"
import json
import os
from pathlib import Path

MANAGED_URL = "http://127.0.0.1:8787"

path = Path.home() / ".claude" / "settings.json"
try:
    data = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    if path.exists():
        path.rename(path.with_suffix(path.suffix + ".bak"))
    data = {}

env = data.get("env")
if not isinstance(env, dict):
    env = {}
current = env.get("ANTHROPIC_BASE_URL")
changed = False

if os.environ["HEADROOM_ROUTE_ACTION"] == "add":
    if current is None or current == MANAGED_URL:
        if current != MANAGED_URL:
            env["ANTHROPIC_BASE_URL"] = MANAGED_URL
            changed = True
    else:
        print(f"Claude settings env already sets ANTHROPIC_BASE_URL={current}; leaving it untouched")
elif current == MANAGED_URL:
    del env["ANTHROPIC_BASE_URL"]
    changed = True

if changed:
    if env:
        data["env"] = env
    elif "env" in data:
        del data["env"]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")
PY

# Compress large tool outputs automatically in every Claude Code session via a managed
# PostToolUse hook. Desktop-spawned sessions pin ANTHROPIC_BASE_URL to the production endpoint
# (headroom #869) so the proxy never sees their traffic, and the CLAUDE.md guidance above only
# helps when the model remembers to call the MCP tools. The hook closes that gap: outputs over
# ~4000 chars from Bash/Grep/Glob/WebFetch are compressed with Headroom's rule-based pipeline
# and swapped in through hookSpecificOutput.updatedToolOutput, with the original kept in the
# shared CCR store so the model can fetch it back with mcp__headroom__headroom_retrieve. The
# script fails open (any error leaves the tool output untouched) and its --self-test gate
# keeps a broken interpreter path from registering a hook that would warn on every tool call.
HEADROOM_HOOK_CMD="/usr/local/bin/headroom-posttooluse-compress.py"
HEADROOM_HOOK_ACTION="remove"
if $HEADROOM_ENABLED && bashio::config.true 'headroom_auto_compress'; then
    if run_as_runtime_user "$HEADROOM_HOOK_CMD" --self-test; then
        HEADROOM_HOOK_ACTION="add"
        bashio::log.info "Registering the Headroom PostToolUse auto-compression hook"
    else
        bashio::log.warning "headroom-posttooluse-compress.py --self-test failed; not registering the auto-compression hook"
    fi
fi
manage_settings_hook PostToolUse "Bash|Grep|Glob|WebFetch" "$HEADROOM_HOOK_CMD" "$HEADROOM_HOOK_ACTION"

# Tell Claude Code that it can configure Home Assistant over the Core API via the shipped
# `ha-cli` helper (no /config filesystem mount needed).
if bashio::config.true 'enable_ha_api_helper'; then
    manage_claude_md_block ha-api-helper add <<'MD'
## Configuring Home Assistant

You can configure this Home Assistant instance through its Core API using the `ha-cli`
command (on `PATH`). It authenticates automatically with the add-on's `$SUPERVISOR_TOKEN`,
so no token setup is needed. There is **no `/config` filesystem mount** — work only through
`ha-cli`, and never try to read or write Home Assistant YAML files directly.

What is editable this way: automations, scripts, and scenes
(`ha-cli get|post|delete config/automation/config/<id>` and the `script`/`scene` equivalents);
service calls (`ha-cli call <domain.service> '<json>'`); state reads (`ha-cli states`); and,
over WebSocket, helpers, dashboards, and area/label/floor/entity registries
(`ha-cli ws '{"type":"..."}'`). Run `ha-cli --help` for the full reference. Raw YAML
(`configuration.yaml`, `secrets.yaml`) is intentionally unreachable — if a change needs it,
say so instead of working around it.

Rules: run `ha-cli config` first to confirm connectivity; **read the current object and show
the user the intended change, then wait for confirmation** before any create/update/delete or
any state-changing `call`; after writing, read the object back and reload if needed
(e.g. `ha-cli call automation.reload`).
MD
else
    manage_claude_md_block ha-api-helper remove
fi

if bashio::config.true 'install_rtk'; then
    if command -v rtk &> /dev/null; then
        bashio::log.info "Configuring rtk Claude Code integration"
        # `rtk init -g` writes ~/.claude/RTK.md and its @RTK.md include in CLAUDE.md, but in
        # non-interactive mode it deliberately refuses to patch settings.json, so the hook
        # entry that actually rewrites Bash commands is registered here.
        run_as_runtime_user env RTK_NONINTERACTIVE=1 rtk init -g \
            || bashio::log.warning "rtk global files configuration failed"
        manage_settings_hook PreToolUse Bash "rtk hook claude" add
    else
        bashio::log.warning "rtk is not available"
    fi
else
    manage_settings_hook PreToolUse Bash "rtk hook claude" remove
fi

if bashio::config.true 'install_caveman'; then
    if [ -d "$HOME/.claude/plugins/caveman" ] || find "$HOME/.claude" -maxdepth 4 -iname '*caveman*' -print -quit | grep -q .; then
        bashio::log.info "caveman Claude Code plugin already configured"
    else
        bashio::log.info "Installing caveman Claude Code plugin"
        curl --connect-timeout 10 --max-time 60 -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash > /dev/null \
            || bashio::log.warning "caveman install failed (offline?)"
    fi
else
    bashio::log.info "Disabling caveman Claude Code plugin"
    find "$HOME/.claude" -maxdepth 4 -iname '*caveman*' -exec rm -rf {} + 2> /dev/null || true
fi

# Ownership of everything written above is reconciled by 84-claude_runtime_ownership.sh after
# the remaining Claude configuration scripts have run.
