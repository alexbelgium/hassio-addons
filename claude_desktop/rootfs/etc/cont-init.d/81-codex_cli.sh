#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

# OpenAI Codex CLI, installed on demand rather than baked into the image: the Linux release
# binary is ~310 MB extracted and the option is off by default. Runs before 82-claude_tools.sh
# so the binary exists when that script registers the `codex` MCP server (cont-init.d executes
# in lexicographic order and "81-claude_update.sh" < "81-codex_cli.sh").
#
# The install prefix is /data/codex, NOT $HOME/.codex/bin, for two reasons: /data is the
# add-on's own persistent volume regardless of the configurable data_location, and the managed
# MCP merge in 82-claude_tools.sh deliberately treats any server command under $HOME as
# user-installed and refuses to manage it — an add-on-owned binary must live outside $HOME to
# stay updatable and removable. Only Codex's own state (auth.json, config.toml) lives in
# $HOME/.codex, which is where Codex itself expects it.
CODEX_PREFIX="/data/codex/bin"
CODEX_BIN="${CODEX_PREFIX}/codex"
CODEX_STAMP="${CODEX_PREFIX}/.version"
CODEX_LINK="/usr/local/bin/codex"

run_as_runtime_user() {
    s6-setuidgid abc env HOME="$HOME" "$@"
}

if ! bashio::config.true 'install_codex_cli'; then
    # Deliberately non-destructive, matching how TokenSave's own indexes are left alone when
    # disabled: an existing binary and — more importantly — a completed ChatGPT sign-in survive
    # a disable/re-enable cycle without another download or another device-code login.
    # 82-claude_tools.sh removes the MCP registration on its own.
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

CODEX_WANTED="${CODEX_VERSION:-}"
if [ -z "$CODEX_WANTED" ]; then
    bashio::log.warning "CODEX_VERSION is not set in the image; cannot determine which Codex release to install"
    exit 0
fi

mkdir -p "$CODEX_PREFIX"

# Re-download only when the pinned version changed or the current binary is unusable, so this
# is a one-time ~113 MB fetch rather than a per-boot cost.
if [ -x "$CODEX_BIN" ] && [ "$(cat "$CODEX_STAMP" 2> /dev/null || true)" = "$CODEX_WANTED" ] \
    && run_as_runtime_user "$CODEX_BIN" --version > /dev/null 2>&1; then
    bashio::log.info "Codex CLI ${CODEX_WANTED} already installed"
else
    CODEX_URL="https://github.com/openai/codex/releases/download/rust-v${CODEX_WANTED}/codex-${CODEX_TARGET}.tar.gz"
    bashio::log.info "Installing Codex CLI ${CODEX_WANTED} (${CODEX_TARGET}); this downloads ~110 MB on first use"
    # Staged under /data, never the default /tmp: /tmp here is a RAM-backed tmpfs, and holding
    # the 110 MB archive plus the 310 MB binary in RAM during boot is a real risk on a small
    # Home Assistant host. /tmp is also mounted noexec, so the downloaded binary could not be
    # verified there anyway. Staging on the same filesystem as the destination additionally
    # makes the final `mv` an atomic rename instead of a second 310 MB copy.
    #
    # Fails open on purpose (same contract as 81-claude_update.sh): an offline boot, a GitHub
    # outage or a bad pin must never abort add-on startup, and must never replace a working
    # binary with a truncated one — hence download, extract and run --version in the staging
    # directory, and only move into place once the binary has proven it executes.
    if codex_tmp="$(mktemp -d -p /data/codex)" \
        && curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
            -o "${codex_tmp}/codex.tar.gz" "$CODEX_URL" \
        && tar -xzf "${codex_tmp}/codex.tar.gz" -C "$codex_tmp" \
        && [ -f "${codex_tmp}/codex-${CODEX_TARGET}" ] \
        && chmod 0755 "${codex_tmp}/codex-${CODEX_TARGET}" \
        && "${codex_tmp}/codex-${CODEX_TARGET}" --version > /dev/null 2>&1 \
        && mv -f "${codex_tmp}/codex-${CODEX_TARGET}" "$CODEX_BIN"; then
        printf '%s' "$CODEX_WANTED" > "$CODEX_STAMP"
        bashio::log.info "Codex CLI installed: $("$CODEX_BIN" --version 2> /dev/null || echo unknown)"
    elif [ -x "$CODEX_BIN" ]; then
        bashio::log.warning "Codex CLI ${CODEX_WANTED} download failed (offline?); keeping the existing install"
    else
        bashio::log.warning "Codex CLI ${CODEX_WANTED} download failed (offline?); Codex is unavailable this boot"
    fi
    rm -rf "${codex_tmp:-/nonexistent}"
fi

if [ ! -x "$CODEX_BIN" ]; then
    exit 0
fi

chown -R -- "$(id -u abc):$(id -g abc)" /data/codex || bashio::log.warning "Unable to set ownership on /data/codex"
ln -sfn "$CODEX_BIN" "$CODEX_LINK"

# Pin the sandbox and approval policy that plain terminal `codex` / `codex exec` runs use.
# The MCP registration in 82-claude_tools.sh passes the same values as `-c` overrides, so MCP
# sessions do not depend on this file — this block exists so both entry points behave the same.
#
# The block must sit at the TOP of config.toml: in TOML a bare key written after a [table]
# header belongs to that table, so appending (the way manage_claude_md_block works for
# CLAUDE.md) would silently produce a different setting. Hence a dedicated writer that strips
# any previously managed block and re-inserts it at position 0, leaving user content below it
# untouched and skipping the write entirely when nothing changed.
CODEX_SANDBOX_MODE="$(bashio::config 'codex_sandbox_mode' 'danger-full-access')"
run_as_runtime_user mkdir -p "$HOME/.codex"
CODEX_SANDBOX_MODE="$CODEX_SANDBOX_MODE" run_as_runtime_user python3 - <<'PY' || bashio::log.warning "Unable to update the managed Codex configuration block"
import os
import re
from pathlib import Path

BEGIN = "# BEGIN managed by claude_desktop addon"
END = "# END managed by claude_desktop addon"

block = "\n".join(
    [
        BEGIN,
        "# Codex's own OS sandbox (Landlock / bundled bubblewrap) is unreliable inside a Home",
        "# Assistant add-on container, which is already the security boundary. Change this",
        "# through the add-on's codex_sandbox_mode option, not here.",
        f'sandbox_mode = "{os.environ["CODEX_SANDBOX_MODE"]}"',
        "# MCP- and cron-driven runs have nobody to answer an approval prompt.",
        'approval_policy = "never"',
        END,
    ]
)

path = Path.home() / ".codex" / "config.toml"
original = path.read_text(encoding="utf-8") if path.exists() else ""
rest = re.sub(
    rf"{re.escape(BEGIN)}.*?{re.escape(END)}\n?",
    "",
    original,
    flags=re.DOTALL,
).lstrip("\n")
new = block + "\n" + (("\n" + rest) if rest else "")
if new != original:
    path.write_text(new, encoding="utf-8")
PY

if [ -f "$HOME/.codex/auth.json" ]; then
    bashio::log.info "Codex CLI is signed in"
else
    bashio::log.info "Codex CLI is not signed in yet; run 'codex-login' to activate your ChatGPT subscription"
fi
