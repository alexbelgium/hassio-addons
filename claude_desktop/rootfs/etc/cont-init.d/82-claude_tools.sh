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

# Codex CLI is installed by 81-codex_cli.sh into /data/codex/bin — deliberately outside $HOME,
# because is_managed() below treats any command under $HOME as user-installed.
CODEX_BIN="/data/codex/bin/codex"
CODEX_ENABLED=false
CODEX_SANDBOX_MODE="$(bashio::config 'codex_sandbox_mode' 'workspace-write')"
if bashio::config.true 'install_codex_cli'; then
    if [ -x "$CODEX_BIN" ]; then
        CODEX_ENABLED=true
        bashio::log.info "codex $("$CODEX_BIN" --version 2> /dev/null || true) available; registering the codex MCP server (sandbox: ${CODEX_SANDBOX_MODE})"
    else
        bashio::log.warning "codex is not available"
    fi
fi

HA_MCP_ENABLED=false
HA_MCP_TOKEN=""
# Read unconditionally, even when enable_ha_mcp is off. Home Assistant keeps an option's value
# when its toggle is disabled, and the reconciliation below needs this URL to recognise the
# HTTP entry it previously wrote so that it can be removed — together with the bearer token
# inside it — rather than orphaned in ~/.claude.json.
HA_MCP_URL="$(bashio::config 'ha_mcp_url' 'http://homeassistant:8123/api/mcp')"
if bashio::config.true 'enable_ha_mcp'; then
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

# Which of the managed MCP servers each client gets.
#
# Every stdio MCP server is a separate process *per client*, and Claude Desktop starts another
# full set for each Claude Code session it hosts — so a server registered in both clients is
# paid for several times over. Measured on a live add-on with three sets running, the private
# (non-shared) resident cost was roughly 54 MB per extra `headroom mcp serve`, 45 MB per extra
# `mcp-proxy`, and only ~11 MB and ~2 MB for `codex` and `tokensave`, which share most of their
# pages. Registering a server only where it is actually used is therefore the cheapest lever
# available; these two options expose that choice.
#
# Defaults keep every enabled server in both clients, i.e. the pre-existing behaviour.
MCP_ALL_SERVERS="headroom tokensave homeassistant codex"

mcp_client_list() {
    local option="$1"
    local selected=() entry raw rc=0

    # An option that is absent entirely — i.e. an existing install upgrading from a config that
    # predates these options — keeps the previous behaviour of registering every enabled server.
    # bashio distinguishes this from an explicitly empty list: an unset key yields the literal
    # "null", while `[]` yields an empty string. Those must not be conflated, because an empty
    # list is a legitimate way to say "no MCP servers in this client" and defaulting it back to
    # all four would silently ignore the user.
    if ! bashio::config.exists "$option"; then
        echo "$MCP_ALL_SERVERS"
        return 0
    fi

    # Capture first: reading a bashio list straight into `while read` via process substitution
    # silently yields nothing under this script's errexit. The exit status is kept separately
    # so that a failed read is not mistaken for a deliberate empty selection.
    raw="$(bashio::config "$option" 2> /dev/null)" || rc=$?
    if [ "$rc" -ne 0 ]; then
        bashio::log.warning "Could not read '${option}'; registering every enabled MCP server for this client"
        echo "$MCP_ALL_SERVERS"
        return 0
    fi

    while read -r entry; do
        [ -n "$entry" ] || continue
        # Reconciliation deletes any managed server not named here, so an unrecognised value
        # must never be treated as an authoritative selection.
        case " $MCP_ALL_SERVERS " in
            *" $entry "*) selected+=("$entry") ;;
            *)
                bashio::log.warning "Ignoring unknown MCP server '${entry}' in '${option}'; registering every enabled server for this client"
                echo "$MCP_ALL_SERVERS"
                return 0
                ;;
        esac
    done <<< "$raw"

    echo "${selected[@]:-}"
}

MCP_SERVERS_DESKTOP="$(mcp_client_list 'mcp_servers_desktop')"
MCP_SERVERS_CODE="$(mcp_client_list 'mcp_servers_code')"
bashio::log.info "MCP servers for Claude Desktop: ${MCP_SERVERS_DESKTOP}"
bashio::log.info "MCP servers for Claude Code: ${MCP_SERVERS_CODE}"

HEADROOM_ENABLED="$HEADROOM_ENABLED" HEADROOM_BIN="$(command -v headroom || echo headroom)" \
    HEADROOM_HF_HOME="${HOME}/.headroom/hf" \
    TOKENSAVE_ENABLED="$TOKENSAVE_ENABLED" TOKENSAVE_BIN="$(command -v tokensave || echo tokensave)" \
    CODEX_ENABLED="$CODEX_ENABLED" CODEX_BIN="$CODEX_BIN" CODEX_SANDBOX_MODE="$CODEX_SANDBOX_MODE" \
    HA_MCP_ENABLED="$HA_MCP_ENABLED" HA_MCP_URL="$HA_MCP_URL" HA_MCP_TOKEN="$HA_MCP_TOKEN" \
    MCP_PROXY_BIN="$(command -v mcp-proxy || echo mcp-proxy)" \
    MCP_SERVERS_DESKTOP="$MCP_SERVERS_DESKTOP" MCP_SERVERS_CODE="$MCP_SERVERS_CODE" \
    CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_CONFIG" CLAUDE_CODE_CONFIG="$CLAUDE_CODE_CONFIG" \
    python3 - <<'PY' || bashio::log.warning "Unable to update the MCP server registrations automatically"
import json
import os
from pathlib import Path

MANAGED_BASENAMES = {
    "headroom": "headroom",
    "tokensave": "tokensave",
    "homeassistant": "mcp-proxy",
    "codex": "codex",
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
if os.environ["CODEX_ENABLED"] == "true":
    # `codex mcp-server` exposes Codex itself as an stdio MCP server (tools: codex, codex-reply),
    # which is what lets a Claude session hand a task to ChatGPT Codex. The sandbox/approval
    # policy is pinned with root-level `-c` overrides, which Codex forwards to the MCP server;
    # they must precede the subcommand. approval_policy is always "never" because an MCP-driven
    # run has nobody to answer a prompt. The sandbox defaults to workspace-write; users can opt
    # into danger-full-access explicitly if the nested sandbox is unavailable in their container.
    # 81-codex_cli.sh writes the same values into ~/.codex/config.toml so plain terminal `codex`
    # runs behave identically.
    desired["codex"] = {
        "command": os.environ["CODEX_BIN"],
        "args": [
            "-c",
            f'sandbox_mode="{os.environ["CODEX_SANDBOX_MODE"]}"',
            "-c",
            'approval_policy="never"',
            "mcp-server",
        ],
    }
if os.environ["HA_MCP_ENABLED"] == "true":
    # Home Assistant's MCP Server integration speaks stateless Streamable HTTP on /api/mcp;
    # mcp-proxy defaults to SSE, so the transport flags are required.
    desired["homeassistant"] = {
        "command": os.environ["MCP_PROXY_BIN"],
        "args": ["--transport=streamablehttp", "--stateless", os.environ["HA_MCP_URL"]],
        "env": {"API_ACCESS_TOKEN": os.environ["HA_MCP_TOKEN"]},
    }

# Claude Code speaks Streamable HTTP MCP natively, so pointing it straight at Home Assistant
# removes the mcp-proxy bridge process entirely — it exists only to translate stdio to the HTTP
# transport Home Assistant already serves. That bridge was the most expensive duplicate
# measured (~45 MB of private RSS per copy, one per Claude Code session).
#
# Claude Desktop keeps the stdio bridge. Its bundled MCP SDK does contain a remote transport,
# but the shape `claude_desktop_config.json` accepts for a remote entry — and whether it
# persists a static bearer header — could not be confirmed, and a wrong guess would silently
# break Home Assistant access in Desktop. Revisit once that schema is verified upstream.
HA_MCP_CODE_ENTRY = None
if os.environ["HA_MCP_ENABLED"] == "true":
    HA_MCP_CODE_ENTRY = {
        "type": "http",
        "url": os.environ["HA_MCP_URL"],
        "headers": {"Authorization": "Bearer " + os.environ["HA_MCP_TOKEN"]},
    }

# An entry is add-on-managed when its command is one of our binaries living outside the
# persistent home. Matching on the basename (rather than the exact path recorded at write
# time) keeps entries updatable when a base-image upgrade moves the binary, while commands
# under $HOME stay untouched because those are user-installed.
HOME_PREFIX = os.path.expanduser("~") + os.sep


def is_managed_http_ha(entry):
    """Recognise the HTTP Home Assistant entry this script writes.

    Ownership requires *both* the exact shape this script generates and the currently
    configured ha_mcp_url. Shape alone is far too weak — a hand-written remote server named
    "homeassistant" with a bearer header has exactly that shape and would be deleted.

    HA_MCP_URL is therefore read even when enable_ha_mcp is off, so that turning the
    integration off still removes the entry (and the token in it) instead of orphaning it.
    A user who both disables the integration and clears ha_mcp_url keeps a stale entry; that
    is the deliberate trade, and it errs towards never touching something that is not ours.
    """
    configured_url = os.environ.get("HA_MCP_URL", "")
    return (
        bool(configured_url)
        and entry.get("url") == configured_url
        and set(entry) == {"type", "url", "headers"}
        and entry.get("type") == "http"
        and isinstance(entry.get("headers"), dict)
        and set(entry["headers"]) == {"Authorization"}
    )


def is_managed(name, entry):
    if not isinstance(entry, dict):
        return False
    command = entry.get("command")
    if not isinstance(command, str) or command.startswith(HOME_PREFIX):
        # A commandless entry is ours only when it is the HTTP Home Assistant registration we
        # write. Anything else — including a user's own remote server that happens to reuse
        # the name — is left alone.
        if command is None and name == "homeassistant":
            return is_managed_http_ha(entry)
        return False
    return os.path.basename(command) == MANAGED_BASENAMES[name]


SELECTED = {
    "CLAUDE_DESKTOP_CONFIG": set(os.environ["MCP_SERVERS_DESKTOP"].split()),
    "CLAUDE_CODE_CONFIG": set(os.environ["MCP_SERVERS_CODE"].split()),
}

for config_var, stdio_type in (("CLAUDE_DESKTOP_CONFIG", False), ("CLAUDE_CODE_CONFIG", True)):
    path = Path(os.environ[config_var])
    selected = SELECTED[config_var]
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
        if name in desired and name in selected:
            if stdio_type and name == "homeassistant" and HA_MCP_CODE_ENTRY is not None:
                # Claude Code talks to Home Assistant over HTTP directly; no bridge process.
                entry = dict(HA_MCP_CODE_ENTRY)
            else:
                entry = dict(desired[name])
                if stdio_type:
                    entry["type"] = "stdio"
            if existing is None or is_managed(name, existing):
                if existing != entry:
                    servers[name] = entry
                    changed = True
        elif existing is not None and is_managed(name, existing):
            # Covers both "feature disabled" and "deselected for this client".
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

# Registering the MCP server is not enough on its own: without guidance the model rarely reaches
# for a second agent, the same gap the Headroom block above exists to close.
if $CODEX_ENABLED; then
    manage_claude_md_block codex add <<'MD'
## Delegating to ChatGPT Codex

The `codex` MCP server runs OpenAI's Codex agent locally, signed in with the user's ChatGPT
subscription. It is a genuinely independent second agent — a different model family, reading the
files itself — not a search tool. It is slow and costs the user's ChatGPT quota, so use it when a
second opinion is worth minutes, not for routine lookups.

Good uses: an independent review of a design or a risky change before it lands; a second
diagnosis of a bug you have a theory about but cannot confirm; a competing implementation of a
self-contained piece you can then compare against your own.

Call `mcp__codex__codex` with `prompt` and always set `cwd` to the repository being discussed —
Codex reads the files itself, so it needs the right working directory and enough context in the
prompt to act without seeing this conversation. Continue an exchange with
`mcp__codex__codex-reply` (note the hyphen) using the `threadId` it returned, rather than
starting a fresh `codex` call. Treat its answers as a peer's opinion: verify claims about this
codebase before acting on them.
MD
else
    manage_claude_md_block codex remove
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
