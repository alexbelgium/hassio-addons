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
#
# Codex is distributed as a package tree, not as a lone executable: since 0.147.0 every shell and
# file-read tool call is executed by a companion binary, codex-code-mode-host, that Codex looks up
# next to itself. Upstream publishes that tree as the codex-package-<target> release asset, and the
# whole tree is installed here. Its layout is load-bearing and must not be flattened: Codex
# canonicalises its own executable path, requires the parent directory to be named `bin`, and then
# reads codex-package.json, codex-resources/ and codex-path/ from that directory's parent. The
# executable's file name is not part of that contract, which is why codex-real keeps its name.
CODEX_ROOT="/data/codex"
CODEX_PREFIX="${CODEX_ROOT}/bin"
CODEX_BIN="${CODEX_PREFIX}/codex"
CODEX_REAL="${CODEX_PREFIX}/codex-real"
CODEX_HOST="${CODEX_PREFIX}/codex-code-mode-host"
CODEX_MANIFEST="${CODEX_ROOT}/codex-package.json"
CODEX_STAMP="${CODEX_PREFIX}/.version"
CODEX_LINK="/usr/local/bin/codex"
CODEX_RELEASE_API="https://api.github.com/repos/openai/codex/releases/latest"

RUNTIME_HOME="$(getent passwd abc | cut -d: -f6)"
if [ -z "$RUNTIME_HOME" ]; then
    bashio::log.warning "Unable to resolve the abc runtime home; using /data/data"
    RUNTIME_HOME="/data/data"
fi

run_as_runtime_user() {
    s6-setuidgid abc env HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex" "$@"
}

# What "installed" means, in one place. A Codex that is missing its code-mode host, its package
# manifest or its version stamp still starts, authenticates and answers — it simply cannot run a
# single tool call — so presence of the executable alone is not a usable install. The stamp counts
# because it is removed before the first file of a replacement is moved and written after the last,
# so its absence next to an executable means the tree may mix two releases.
codex_install_is_complete() {
    [ -x "$CODEX_REAL" ] \
        && [ -x "$CODEX_HOST" ] \
        && [ -f "$CODEX_MANIFEST" ] \
        && [ -f "$CODEX_STAMP" ]
}

# Move a verified package tree from staging into the install prefix. Called only from an `if`
# condition, where `set -e` does not apply, so every step reports failure explicitly.
#
# The long, failure-prone part of an install — the download and its digest check — is already done
# by the time this runs; what is left is same-filesystem renames of an already validated tree. They
# are not one atomic operation, so the version stamp is removed first: any interruption leaves a
# stamp-less prefix, which the next boot treats as "not installed" and replaces wholesale. The
# entrypoint is moved last, so a prefix whose codex-real is the new release is a prefix whose
# helper binaries are the new release too.
install_codex_package() {
    local staged="$1"
    local optional
    rm -f -- "$CODEX_STAMP" || return 1
    rm -rf -- "${CODEX_ROOT}/codex-resources" "${CODEX_ROOT}/codex-path" || return 1
    # codex-resources/ and codex-path/ hold optional helpers (bubblewrap, zsh, ripgrep) that Codex
    # falls back to system copies for, so a target that ships without them still installs.
    for optional in codex-resources codex-path; do
        if [ -d "${staged}/${optional}" ]; then
            mv -f -- "${staged}/${optional}" "${CODEX_ROOT}/${optional}" || return 1
        fi
    done
    mv -f -- "${staged}/codex-package.json" "$CODEX_MANIFEST" || return 1
    mv -f -- "${staged}/bin/codex-code-mode-host" "$CODEX_HOST" || return 1
    mv -f -- "${staged}/bin/codex" "$CODEX_REAL" || return 1
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

CODEX_ASSET="codex-package-${CODEX_TARGET}.tar.gz"
mkdir -p "$CODEX_PREFIX"

# Migrate the PR's earlier direct-binary layout to the enforced wrapper layout without another
# download. The real binary is kept separately; `codex` becomes a small launcher that always
# forces ChatGPT subscription authentication and removes any inherited API key.
if [ ! -x "$CODEX_REAL" ] \
    && [ -x "$CODEX_BIN" ] \
    && run_as_runtime_user "$CODEX_BIN" --version > /dev/null 2>&1; then
    mv -f "$CODEX_BIN" "$CODEX_REAL"
fi

# Resolve the latest stable release and its GitHub-published SHA-256 digest on every boot. This
# follows upstream updates without pinning a version, while downloading the large asset only when
# the installed version changes. A metadata outage never replaces or removes a working binary.
codex_tmp="$(mktemp -d -p "$CODEX_ROOT")"
# mktemp always creates 0700 root:root here, but the candidate binary is validated by running it
# as the abc runtime user, which cannot traverse a root-only directory — that made every install
# fail at the --version step with "unable to exec: Permission denied" (exit 126) and report
# "Codex is unavailable this boot". Make the staging directory traversable. Nothing secret is
# staged here: it holds the public release archive and the extracted binary, both of which are
# world-readable upstream artifacts, and cleanup() removes the directory on exit.
chmod 0755 "$codex_tmp"
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
    if codex_install_is_complete && run_as_runtime_user "$CODEX_REAL" --version > /dev/null 2>&1; then
        bashio::log.warning "Unable to resolve the latest verified Codex release; keeping the existing install"
    else
        bashio::log.warning "Unable to resolve the latest verified Codex release; the installed Codex is missing or incomplete and stays unavailable until a boot can reach the release metadata"
    fi
else
    IFS=$'\t' read -r CODEX_WANTED CODEX_SHA256 CODEX_URL <<< "$release_info"

    # An install is complete only if the code-mode host and the package manifest are there too:
    # every install made before this add-on switched to the package asset has a working codex-real
    # and no helpers, and repairs itself here rather than needing a fresh /data. Running the binary
    # also rejects one built for another architecture, which a restored backup could leave behind.
    if codex_install_is_complete \
        && [ "$(cat "$CODEX_STAMP" 2> /dev/null || true)" = "$CODEX_WANTED" ] \
        && run_as_runtime_user "$CODEX_REAL" --version > /dev/null 2>&1; then
        bashio::log.info "Codex CLI ${CODEX_WANTED} already installed (latest stable)"
    else
        bashio::log.info "Installing latest stable Codex CLI ${CODEX_WANTED} (${CODEX_TARGET}); this is a large one-time download"
        archive="${codex_tmp}/${CODEX_ASSET}"
        staged="${codex_tmp}/package"

        # Fail open for add-on startup but fail closed for the candidate release: its official
        # release digest must match before extraction or execution, and replacement happens only
        # after the staged tree is complete and its entrypoint successfully runs. The candidate is
        # exercised in staging with its own codex-package.json and helper directories in place, so
        # the layout Codex will resolve at runtime is the layout that was validated.
        if mkdir -p "$staged" \
            && chmod 0755 "$staged" \
            && curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 600 \
                -o "$archive" "$CODEX_URL" \
            && printf '%s  %s\n' "$CODEX_SHA256" "$archive" | sha256sum -c - > /dev/null \
            && tar -xzf "$archive" -C "$staged" \
            && [ -f "${staged}/codex-package.json" ] \
            && [ -f "${staged}/bin/codex" ] \
            && [ -f "${staged}/bin/codex-code-mode-host" ] \
            && chmod 0755 "${staged}/bin/codex" "${staged}/bin/codex-code-mode-host" \
            && run_as_runtime_user "${staged}/bin/codex" --version > /dev/null 2>&1 \
            && install_codex_package "$staged"; then
            printf '%s' "$CODEX_WANTED" > "$CODEX_STAMP"
            bashio::log.info "Codex CLI installed: $("$CODEX_REAL" --version 2> /dev/null || echo unknown)"
        elif codex_install_is_complete; then
            bashio::log.warning "Verified Codex ${CODEX_WANTED} installation failed; keeping the existing install"
        else
            bashio::log.warning "Verified Codex ${CODEX_WANTED} installation failed; Codex is unavailable this boot"
        fi
    fi
fi

# The launcher is the add-on's single "Codex is usable" signal: 82-claude_tools.sh registers the
# Codex MCP server when it is executable and re-checks nothing else. Write it only for a complete
# install, and remove it — together with the PATH symlink — for an incomplete one. Both the launcher
# and the package tree live in /data and survive restarts independently, so a launcher left from an
# earlier boot would otherwise outlive the install it was written for and advertise a Codex whose
# every tool call fails. The executable, the package tree and the ChatGPT sign-in are all left in
# place: a later boot completes the install without another download or another login.
if ! codex_install_is_complete; then
    rm -f -- "$CODEX_BIN" "$CODEX_LINK"
    bashio::log.warning "Codex is not completely installed; not registering it this boot"
    exit 0
fi

# Every Codex entry point, including the MCP server launched by Claude, goes through this wrapper.
# This is an execution-time guarantee in addition to the managed config below: API-key billing
# cannot be selected even if an API key is present in the surrounding environment. Caller-provided
# overrides for the two authentication guards are stripped before the forced root-level overrides
# are inserted; root-level -c flags must precede Codex subcommands such as `mcp-server`.
{
    printf '#!/usr/bin/env bash\n'
    printf 'CODEX_REAL=%q\n' "$CODEX_REAL"
    cat <<'SH'
RUNTIME_HOME="$(getent passwd abc | cut -d: -f6)"
if [ -z "$RUNTIME_HOME" ]; then
    echo "codex: unable to resolve the abc runtime home" >&2
    exit 1
fi

is_managed_override() {
    local assignment="$1"
    local key="${assignment%%=*}"
    key="${key//[[:space:]]/}"
    case "$key" in
        forced_login_method | cli_auth_credentials_store) return 0 ;;
        *) return 1 ;;
    esac
}

filtered_args=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -c | --config)
            if [ "$#" -lt 2 ]; then
                filtered_args+=("$1")
                shift
                continue
            fi
            if is_managed_override "$2"; then
                shift 2
                continue
            fi
            filtered_args+=("$1" "$2")
            shift 2
            ;;
        --config=*)
            assignment="${1#--config=}"
            if ! is_managed_override "$assignment"; then
                filtered_args+=("$1")
            fi
            shift
            ;;
        -c*)
            assignment="${1#-c}"
            if ! is_managed_override "$assignment"; then
                filtered_args+=("$1")
            fi
            shift
            ;;
        *)
            filtered_args+=("$1")
            shift
            ;;
    esac
done

forced_args=(
    -c 'forced_login_method="chatgpt"'
    -c 'cli_auth_credentials_store="file"'
)

if [ "$(id -u)" -eq 0 ]; then
    exec s6-setuidgid abc env -u OPENAI_API_KEY \
        HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex" \
        "$CODEX_REAL" "${forced_args[@]}" "${filtered_args[@]}"
fi

unset OPENAI_API_KEY
export HOME="$RUNTIME_HOME"
export CODEX_HOME="$RUNTIME_HOME/.codex"
exec "$CODEX_REAL" "${forced_args[@]}" "${filtered_args[@]}"
SH
} > "$CODEX_BIN"
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
