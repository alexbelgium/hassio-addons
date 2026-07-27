#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

# OpenAI Codex CLI, installed on demand rather than baked into the image: the Linux release
# binary is large and the option is off by default. Runs before 82-claude_tools.sh so the binary
# exists when that script registers the `codex` MCP server.
#
# The install prefix is /data/codex, NOT $HOME/.codex/bin: /data is persistent regardless of the
# configurable data_location, and the managed MCP merge treats commands under $HOME as
# user-installed. Codex state (auth.json, config.toml) remains in the runtime user's home.
CODEX_ROOT="/data/codex"
CODEX_PREFIX="${CODEX_ROOT}/bin"
CODEX_BIN="${CODEX_PREFIX}/codex"
CODEX_REAL="${CODEX_PREFIX}/codex-real"
CODEX_STAMP="${CODEX_PREFIX}/.version"
CODEX_LINK="/usr/local/bin/codex"
CODEX_RELEASE_API="https://api.github.com/repos/openai/codex/releases/latest"

RUNTIME_HOME="$(getent passwd abc | cut -d: -f6)"
if [ -z "$RUNTIME_HOME" ]; then
    bashio::log.warning "Unable to resolve the abc runtime home; using /data/data"
    RUNTIME_HOME="/data/data"
fi

run_as_runtime_user() {
    s6-setuidgid abc env HOME="$RUNTIME_HOME" "$@"
}

if ! bashio::config.true 'install_codex_cli'; then
    # Non-destructive: preserve the binary and completed ChatGPT sign-in for a later re-enable.
    # 82-claude_tools.sh removes only the MCP registration and managed guidance.
    bashio::log.info "Codex CLI disabled"
    exit 0
fi

case "$(uname -m)" in
    x86_64) CODEX_TARGET="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) CODEX_TARGET="aarch64-unknown-linux-musl" ;;
    *)
        bashio::log.warning "Codex CLI has no release binary for $(uname -m); skipping"
        exit 0
        ;;
esac

CODEX_ASSET="codex-${CODEX_TARGET}.tar.gz"
mkdir -p "$CODEX_PREFIX"

# Migrate the PR's earlier direct-binary layout to the enforced wrapper layout without another
# download. The real binary is kept separately; `codex` becomes a small launcher that always
# forces ChatGPT subscription authentication and removes any inherited API key.
if [ ! -x "$CODEX_REAL" ] && [ -x "$CODEX_BIN" ]; then
    mv -f "$CODEX_BIN" "$CODEX_REAL"
fi

# Resolve the latest stable release and its GitHub-published SHA-256 digest on every boot. This
# follows upstream updates without pinning a version, while downloading the large asset only when
# the installed version changes. A metadata outage never replaces or removes a working binary.
codex_tmp="$(mktemp -d -p "$CODEX_ROOT")"
cleanup() {
    rm -rf "$codex_tmp"
}
trap cleanup EXIT

release_metadata="${codex_tmp}/release.json"
release_info=""
if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 30 \
    -o "$release_metadata" "$CODEX_RELEASE_API"; then
    release_info="$(
        CODEX_ASSET="$CODEX_ASSET" python3 - "$release_metadata" <<'PY' 2> /dev/null || true
import json
import os
import re
import sys
from pathlib import Path

metadata = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
tag = metadata.get("tag_name", "")
if not isinstance(tag, str) or not tag.startswith("rust-v"):
    raise SystemExit("unexpected release tag")
version = tag.removeprefix("rust-v")
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-(?:alpha|beta)(?:\.[0-9]+){0,2})?", version):
    raise SystemExit("unexpected release version")

asset_name = os.environ["CODEX_ASSET"]
asset = next(
    (
        item
        for item in metadata.get("assets", [])
        if isinstance(item, dict) and item.get("name") == asset_name
    ),
    None,
)
if asset is None:
    raise SystemExit("release asset missing")
digest = asset.get("digest", "")
if not isinstance(digest, str) or not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest):
    raise SystemExit("release asset has no valid SHA-256 digest")
url = asset.get("browser_download_url", "")
if not isinstance(url, str) or not url.startswith("https://github.com/openai/codex/releases/download/"):
    raise SystemExit("unexpected release asset URL")

print(f"{version}\t{digest.removeprefix('sha256:').lower()}\t{url}")
PY
    )"
fi

if [ -z "$release_info" ]; then
    if [ -x "$CODEX_REAL" ] && run_as_runtime_user "$CODEX_REAL" --version > /dev/null 2>&1; then
        bashio::log.warning "Unable to resolve the latest verified Codex release; keeping the existing install"
    else
        bashio::log.warning "Unable to resolve the latest verified Codex release; Codex is unavailable this boot"
        exit 0
    fi
else
    IFS=$'\t' read -r CODEX_WANTED CODEX_SHA256 CODEX_URL <<< "$release_info"

    if [ -x "$CODEX_REAL" ] \
        && [ "$(cat "$CODEX_STAMP" 2> /dev/null || true)" = "$CODEX_WANTED" ] \
        && run_as_runtime_user "$CODEX_REAL" --version > /dev/null 2>&1; then
        bashio::log.info "Codex CLI ${CODEX_WANTED} already installed (latest stable)"
    else
        bashio::log.info "Installing latest stable Codex CLI ${CODEX_WANTED} (${CODEX_TARGET}); this is a large one-time download"
        archive="${codex_tmp}/${CODEX_ASSET}"
        extracted="${codex_tmp}/codex-${CODEX_TARGET}"

        # Fail open for add-on startup but fail closed for the candidate binary: its official
        # release digest must match before extraction or execution, and replacement happens only
        # after the staged binary successfully runs.
        if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 600 \
            -o "$archive" "$CODEX_URL" \
            && printf '%s  %s\n' "$CODEX_SHA256" "$archive" | sha256sum -c - > /dev/null \
            && tar -xzf "$archive" -C "$codex_tmp" \
            && [ -f "$extracted" ] \
            && chmod 0755 "$extracted" \
            && "$extracted" --version > /dev/null 2>&1 \
            && mv -f "$extracted" "$CODEX_REAL"; then
            printf '%s' "$CODEX_WANTED" > "$CODEX_STAMP"
            bashio::log.info "Codex CLI installed: $("$CODEX_REAL" --version 2> /dev/null || echo unknown)"
        elif [ -x "$CODEX_REAL" ]; then
            bashio::log.warning "Verified Codex ${CODEX_WANTED} installation failed; keeping the existing install"
        else
            bashio::log.warning "Verified Codex ${CODEX_WANTED} installation failed; Codex is unavailable this boot"
        fi
    fi
fi

if [ ! -x "$CODEX_REAL" ]; then
    exit 0
fi

# Every Codex entry point, including the MCP server launched by Claude, goes through this wrapper.
# This is an execution-time guarantee in addition to the managed config below: API-key billing
# cannot be selected even if an API key is present in the surrounding environment.
cat > "$CODEX_BIN" <<'SH'
#!/bin/sh
unset OPENAI_API_KEY
exec /data/codex/bin/codex-real \
    -c 'forced_login_method="chatgpt"' \
    -c 'cli_auth_credentials_store="file"' \
    "$@"
SH
chmod 0755 "$CODEX_BIN"

chown -R -- "$(id -u abc):$(id -g abc)" "$CODEX_ROOT" \
    || bashio::log.warning "Unable to set ownership on ${CODEX_ROOT}"
ln -sfn "$CODEX_BIN" "$CODEX_LINK"

# Manage the root-level defaults used by terminal Codex and by `codex mcp-server`.
#
# `forced_login_method = "chatgpt"` makes subscription authentication the only permitted login
# method, so an inherited OPENAI_API_KEY cannot silently switch this integration to API billing.
# File storage is explicit because the container has no supported OS keyring.
#
# The managed block must be first: a bare TOML key after a [table] header belongs to that table.
# Existing top-level definitions of the managed keys are removed before insertion; retaining them
# would create duplicate keys and make the entire Codex configuration invalid.
CODEX_SANDBOX_MODE="$(bashio::config 'codex_sandbox_mode' 'danger-full-access')"
run_as_runtime_user mkdir -p "$RUNTIME_HOME/.codex"
CODEX_SANDBOX_MODE="$CODEX_SANDBOX_MODE" RUNTIME_HOME="$RUNTIME_HOME" \
    run_as_runtime_user python3 - <<'PY' \
    || bashio::log.warning "Unable to update the managed Codex configuration block"
import os
import re
import tomllib
from pathlib import Path

BEGIN = "# BEGIN managed by claude_desktop addon"
END = "# END managed by claude_desktop addon"
MANAGED_KEYS = {
    "sandbox_mode",
    "approval_policy",
    "forced_login_method",
    "cli_auth_credentials_store",
}

block = "\n".join(
    [
        BEGIN,
        "# Managed defaults for terminal and MCP-driven Codex runs.",
        f'sandbox_mode = "{os.environ["CODEX_SANDBOX_MODE"]}"',
        'approval_policy = "never"',
        "# Require ChatGPT subscription OAuth; do not fall back to API-key billing.",
        'forced_login_method = "chatgpt"',
        "# This container has no supported OS keyring; keep OAuth credentials in auth.json.",
        'cli_auth_credentials_store = "file"',
        END,
    ]
)

path = Path(os.environ["RUNTIME_HOME"]) / ".codex" / "config.toml"
original = path.read_text(encoding="utf-8") if path.exists() else ""
rest = re.sub(
    rf"{re.escape(BEGIN)}.*?{re.escape(END)}\n?",
    "",
    original,
    flags=re.DOTALL,
)

table_header = re.compile(r"^\s*\[\[?.+?\]\]?\s*(?:#.*)?$")
assignment = re.compile(
    r'''^\s*(?P<key>[A-Za-z0-9_-]+|"[^"]+"|'[^']+')\s*='''
)
kept = []
at_top_level = True
for line in rest.splitlines(keepends=True):
    if at_top_level and table_header.match(line):
        at_top_level = False
    match = assignment.match(line) if at_top_level else None
    if match:
        key = match.group("key")
        if key[:1] in {'"', "'"}:
            key = key[1:-1]
        if key in MANAGED_KEYS:
            continue
    kept.append(line)

remainder = "".join(kept).lstrip("\n")
new = block + "\n" + (("\n" + remainder) if remainder else "")
tomllib.loads(new)
if new != original:
    path.write_text(new, encoding="utf-8")
path.chmod(0o600)
PY

if [ -f "$RUNTIME_HOME/.codex/auth.json" ]; then
    bashio::log.info "Codex CLI is signed in with stored ChatGPT credentials"
else
    bashio::log.info "Codex CLI is not signed in yet; run 'codex-login' to activate your ChatGPT subscription"
fi
