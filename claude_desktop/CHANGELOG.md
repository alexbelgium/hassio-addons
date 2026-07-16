## 1.31 (16-07-2026)

- Fix Home Assistant ingress remaining on `Waiting for stream`: current Selkies WebSocket mode connects through `/api/websockets`, while the add-on inherited an older nginx template that proxied only `/websocket`. Replace the template rewrite with an explicit ingress server that proxies `/api/` to Selkies on port 8082, retains `/websocket` compatibility, and declares `ingress_port: 3001` so nginx always receives a valid listen port.

## 1.30 (16-07-2026)

- Compress large tool outputs automatically in every Claude Code session with a managed `PostToolUse` hook (new `headroom_auto_compress` option, enabled by default). Desktop-spawned sessions (cowork/dispatch) pin `ANTHROPIC_BASE_URL` to the production endpoint (headroom #869), so the transparent proxy never sees their traffic and compression there depended entirely on the model remembering to call the `headroom` MCP tools per the CLAUDE.md guidance — in practice most large outputs went uncompressed. The new `/usr/local/bin/headroom-posttooluse-compress.py` hook fires on `Bash`/`Grep`/`Glob`/`WebFetch` results over ~4000 characters, compresses them with Headroom's rule-based pipeline (SmartCrusher and friends; the Kompress ML path is disabled because its background model load can never complete inside a short-lived hook process), and swaps the result in via `hookSpecificOutput.updatedToolOutput` with a retrieval marker appended. Originals are stored in the shared CCR SQLite store (`~/.headroom/ccr_store.db` — the same one the headroom MCP server reads), so `mcp__headroom__headroom_retrieve` always recovers the full output; savings are recorded to the durable ledger (client `posttooluse-hook`) and show up in the existing gains report. The hook fails open (any error leaves the tool output untouched), never touches `stderr` fields so error text reaches the model verbatim, skips anything below a 50-token savings floor, and is registered idempotently in `~/.claude/settings.json` only after a `--self-test` confirms the interpreter can import headroom; disabling the option (or Headroom) removes the managed entry without touching user-defined hooks. Measured on a representative Home Assistant `states` dump: 10781 -> 2964 tokens (73% saved) at ~1.7 s hook overhead, with sub-100 ms pass-through for small outputs.

## 1.29 (16-07-2026)

- Point the Headroom MCP server at the persistent Kompress model cache. 1.27 set `HF_HOME` on the `svc-headroom` proxy longrun only, but the MCP server is a separate process spawned by Claude Desktop / Claude Code from the registered `mcpServers` entry, so it never inherited that export and kept resolving the HuggingFace cache to `~/.cache` — symlinked to tmpfs here and wiped on every restart. Its Kompress ML path therefore never found the model, re-downloaded ~270 MB into tmpfs on each boot, and lost it again on the next one; `headroom_compress` fell back to `router:noop` (unchanged output) on prose and other unstructured content. The managed `headroom` entry in both `claude_desktop_config.json` and `~/.claude.json` now carries `env.HF_HOME` pointing at the same `~/.headroom/hf` cache the proxy warms. Rule-based compression (SmartCrusher, structured tool output) was unaffected and worked throughout.
- Fix `~/.gitconfig` being written as `root` and left unreadable by the `abc` runtime user, which broke git for the user that actually runs it: every commit failed with `Author identity unknown` and the `gh` credential helper was invisible to authenticated pushes. `git config --global` ran as root during init and rewrites the file on every start, so `20-folders.sh`'s earlier recursive chown never stuck to it (`.config/gh` survived abc-owned only because the "already authenticated" branch skips rewriting it). The git/gh setup now runs as `abc` via `s6-setuidgid`, matching `81-tokensave_repositories.sh`, and reclaims any root-owned copies left by an earlier version before writing.
- Fix `~/.bashrc` accumulating stale `HOME`/`FM_HOME` exports when `data_location` changes. The idempotency guard only tested for the *current* `$LOCATION`, so changing the option and later changing it back appended a second block while leaving the first, and the last one written won for every interactive shell — leaving `$HOME` pointing at a directory the add-on no longer manages. Any tool that resolves config through `$HOME` then read the wrong path (`headroom doctor` reported `claude: not routed (no ~/.claude/settings.json)` against a correctly routed install, and bare `headroom` invocations created a stray `.headroom` tree under the old location). The block is now marker-delimited and rewritten from scratch on every boot, so it is idempotent across any number of `data_location` changes.

## 1.27 (15-07-2026)

- Route Claude Desktop cowork/local-agent-mode sessions through the Headroom proxy. Desktop spawns its bundled Claude Code binary at an absolute path (bypassing the add-on's PATH wrapper) with `ANTHROPIC_BASE_URL` pinned to the production endpoint, so those sessions never produced proxy savings. The add-on now manages `env.ANTHROPIC_BASE_URL` in `~/.claude/settings.json` — settings `env` entries replace inherited environment values at CLI startup — gated on `headroom_wrap_claude_code` and never overwriting a user-customized endpoint.
- Fix Headroom's Kompress compression engine never activating, which made even proxied traffic record zero token savings (e.g. 175 requests, 0 saved). The proxy's startup preload is deliberately cache-only, but the HuggingFace model cache defaulted to `~/.cache` — tmpfs in this add-on, wiped every restart — so the ONNX model (plus the separately fetched `answerdotai/ModernBERT-base` tokenizer) was never cached and the engine idled in "deferred" mode forever, misleadingly logged as `Kompress: not installed`. `svc-headroom` now points `HF_HOME` at persistent storage (`~/.headroom/hf`, ~270 MB); the proxy's own request path already downloads a missing model in the background on first use and passes requests through uncompressed until it lands, so no blocking startup pre-warm is needed — the port binds immediately either way, and Kompress activates within the first couple of requests on the first boot, then loads instantly on every boot after. The already-installed `proxy` extra's ONNX runtime is sufficient — the multi-gigabyte PyTorch `ml` extra is deliberately not installed.

## 1.26 (15-07-2026)

- Fix startup permission failures that prevented Claude Desktop from starting: storage was chowned to a hardcoded `1000:1000`, but the shared `abc` desktop user was never mapped to that UID. During init `abc` was still the image default (`911`), so TokenSave (`.claude.json.new`), RTK (`RTK.md`), nginx, PulseAudio, the Mesa shader cache, and Claude Desktop itself all hit `Permission denied`; the base image's `init-adduser` then remapped `abc` to root mid-startup (PUID/PGID were read from add-on options where they did not exist, falling back to `0`), which also made Claude Code reject `permission_mode: bypass`.
- Add `PUID`/`PGID` add-on options (default `1000:1000`) and remap `abc` to that identity at the very start of folder setup, before any ownership is applied and before any service resolves the user. The base image's `init-adduser` is pinned to the same effective identity so it can no longer remap `abc` mid-startup.
- In `permission_mode: bypass`, a configured `PUID: 0` automatically falls back to UID `1000` (Claude Code refuses bypass permissions as root), retaining the configured group.
- Fix `bashio::config.array: command not found` in the TokenSave repository setup, tools configuration, and `claude-tools-doctor.sh`: the function only exists in the repo's standalone bashio, not in the real bashio shipped in the image. Use `bashio::config`, which prints list entries one per line.
- Return managed Claude configuration files to the effective `abc` identity instead of the raw configured `PUID`/`PGID` (which previously fell back to `0` and left the files root-owned).
- Pre-create `/tmp/.X11-unix` with the standard sticky mode so Xorg, which runs as the non-root `abc` user on a tmpfs `/tmp`, no longer fails to create its socket directory (`_XSERVTransmkdir: euid != 0`).

## 1.25 (15-07-2026)
- Minor bugs fixed
## 1.24 (15-07-2026)

- Fix the `/usr/local/bin/claude` wrapper never routing terminal Claude Code sessions through the Headroom proxy: it hardcoded `HEADROOM_BIN="/usr/local/bin/headroom"` while the binary is installed at `/usr/bin/headroom`, so the executable check always failed and the wrapper fell back to launching Claude Code directly. Resolve the binary with `command -v headroom` instead.
- Harden startup TokenSave indexing so an interrupted `init`/`sync` or a hard add-on stop can no longer leave a corrupt semantic graph that fails every subsequent boot. Each configured repository is now prepared under a startup-scoped `flock` (serialised against overlapping restarts and mid-boot git sync hooks); an existing index is refreshed with a retried incremental `sync` (transient `SQLITE_BUSY` no longer looks like corruption); and only a genuinely unreadable index — or a half-written one flagged by an `init` sentinel — is quarantined to `.tokensave/corrupt-<timestamp>/` and rebuilt from scratch, so the graph self-heals instead of propagating corruption.

## 1.23 (15-07-2026)

- Add a `ha-cli` helper that lets Claude configure Home Assistant (automations, scripts, scenes, helpers, dashboards, area/label/floor/entity registries, and service calls) through the Home Assistant Core API instead of a filesystem mount. It authenticates automatically with the add-on's `SUPERVISOR_TOKEN` via the Supervisor Core-API proxy (no token setup), and deliberately cannot reach `configuration.yaml`/`secrets.yaml` or other add-ons' credentials. Toggle with the new `enable_ha_api_helper` option (default on), which also controls a managed guidance block appended to `~/.claude/CLAUDE.md`.

## 1.21 (15-07-2026)

- Fix Claude Code bypass permissions being rejected when the add-on uses its default root `PUID`.
- In `permission_mode: bypass`, remap the shared `abc` Desktop runtime to an unused non-root UID before storage ownership and Selkies startup, while retaining its configured primary group for mounted-path access.
- Make folder setup and final Claude configuration ownership follow the effective `abc` identity instead of the configured root UID.
- Drop root console invocations of the add-on's `/usr/local/bin/claude` wrapper to the non-root `abc` runtime before passing `--dangerously-skip-permissions`.
- Extend `claude-tools-doctor.sh` with configured/effective UID and GID checks for bypass mode.

## 1.20 (15-07-2026)

- Complete the TokenSave Claude Code integration at startup: install its MCP server, permissions, PreToolUse/UserPromptSubmit/Stop hooks, global guidance, and Git synchronization hooks instead of registering only `tokensave serve`.
- Add `tokensave_project_paths` for explicit per-repository initialization and incremental synchronization; no repositories are scanned or indexed unless listed.
- Route PATH-based Claude Code launches through the already-supervised Headroom proxy by default with a recursion-safe `/usr/local/bin/claude` wrapper; fall back to the official binary when the proxy is unavailable.
- Pass the local proxy URL explicitly to the Headroom MCP server, while retaining MCP-only integration for the Desktop Electron application.
- Keep the unauthenticated Headroom dashboard container-local by default; add `expose_headroom_dashboard` and leave port `8787/tcp` unmapped until explicitly enabled.
- Fix the hourly gains report so Headroom no longer suppresses RTK output, add TokenSave gains, and gate each tool on its actual add-on option.
- Add `claude-tools-doctor.sh` to inspect binaries, redacted MCP registrations, hooks, proxy health, routing, project indexes, and gains.
- Install local validation tools (`jq`, `shellcheck`, `yamllint`, current `hadolint`, and current `actionlint`) to reduce avoidable CI round-trips.
- Disable the unpinned third-party Caveman startup installer by default; it remains opt-in.

## 1.19 (14-07-2026)
- Minor bugs fixed
## 1.18 (14-07-2026)

- **Breaking:** remove the standalone Claude Code web terminal (ttyd/tmux service, port `7681`, and the `enable_terminal`, `terminal_username`, `terminal_password`, `terminal_workspace` options). The add-on is now built purely around Claude Desktop; Claude Code remains installed and powers Desktop cowork/dispatch sessions with the RTK hook, Caveman, and MCP servers intact. If the add-on refuses to start after the update, open its Configuration tab and re-save to drop the removed options.
- Remove the `claude-direct` and `claude-headroom` terminal wrapper scripts and the unused `ha_smart_context` and `dangerously_skip_permissions` options.
- Fix the Headroom dashboard being unreachable at `http://<host>:8787/dashboard`: the supervised proxy only listened on `127.0.0.1`; it now binds `0.0.0.0` so the mapped port works.
- Fix dispatch/remote sessions and sign-in persistence: install the missing `gnome-keyring` package. The existing keyring bootstrap silently no-oped without it, leaving Electron `safeStorage` unavailable ("cannot store allowlist cache"), so auth tokens and dispatch permission grants were lost on restart.
- Add the tokensave code-intelligence MCP server (pinned 7.2.0, built from source like RTK), registered for both Claude Desktop and Claude Code; disable with `install_tokensave: false`.
- Implement the Home Assistant MCP bridge for real: `enable_ha_mcp` plus new `ha_mcp_url`/`ha_mcp_token` options register Home Assistant's MCP Server integration in Claude through `mcp-proxy`, using the integration's stateless Streamable HTTP endpoint (`/api/mcp`).
- Write the Claude configuration files with `0600` permissions, since they hold the Home Assistant access token in clear text.
- Restrict the build-time `chmod +x` pass to the directories the add-on actually ships scripts in instead of traversing the whole image.
- Register add-on-managed MCP servers in Claude Code's `~/.claude.json` as well as Claude Desktop's config, without clobbering user-customized entries.
- Install `uv` and use it for the `additional_pip` option for much faster package installs.

## 1.16 (14-07-2026)
- Minor bugs fixed
## 1.15 (13-07-2026)
- Minor bugs fixed
  
## ubunturesolute-version-6dc44b0e (2026-07-13)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
## 1.14 (10-07-2026)

- Build pinned RTK 0.43.0 source on Debian Bookworm for both architectures instead of installing the upstream arm64 release binary, which requires GLIBC 2.39 and cannot run in the add-on image.
- Execute `rtk --version` inside the final image during the Docker build so future ABI incompatibilities fail CI instead of surfacing at runtime.
- Validate the final Bookworm-built RTK binary in a native aarch64 image build.
- Correct the repository PR checks so changed changelog paths are exported and aarch64 images are built explicitly for `linux/arm64`.

## debiantrixie-version-c55d3809 (2026-07-11)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
## 1.13 (10-07-2026)

- Add the official Claude Code stable package, `tmux`, `ripgrep`, and a pinned upstream `ttyd` binary for both supported architectures.
- Add an optional authenticated Claude Code web terminal on port `7681`; the port remains unmapped by default and reconnecting clients attach to the same persistent tmux session.
- Validate and canonicalize `terminal_workspace`, restrict it to supported storage roots, and never re-own existing directories.
- Order the terminal after service initialization and start tmux with an explicit Bash shell and workspace.
- Add `claude-headroom` for Headroom's supported wrapper, reusing the supervised proxy with `--no-proxy` while leaving RTK management to the add-on.
- Keep Claude Desktop on the MCP-only Headroom integration and remove the ineffective `ANTHROPIC_BASE_URL` export from its launch environment.
- Preserve ownership of Claude settings for the configured runtime user and remove only the exact add-on-managed RTK hook when RTK is disabled.
- Fetch the repository-standard helper templates during image construction so the add-on builds from its actual Docker context.
- Install only Headroom's proxy, code-compression, and MCP features instead of unused CUDA, voice, image, memory, and evaluation stacks.
- Document the shared-home architecture, separate Desktop/CLI sessions, direct HTTP terminal security, shared concurrent sessions, and configurable data location.

## 1.12 (09-07-2026)
- Minor bugs fixed
## 1.11 (09-07-2026)
- Minor bugs fixed
## 1.10 (09-07-2026)
- Minor bugs fixed
## 1.9 (08-07-2026)
- Minor bugs fixed
## 1.8 (08-07-2026)

- Expose the Headroom live savings dashboard on mapped port `8787` when `install_headroom` is enabled, while keeping the proxy local-only if the port mapping is disabled.
- Map `8787/tcp` by default and document the dashboard URL.

## 1.7 (07-07-2026)

- Add an hourly rtk + headroom token-savings report to the add-on log (`claude-gains-report.sh`, seeded via `/defaults/crontabs/root` and run by the base image's cron). Lets you confirm at a glance that both tools keep running and see accumulated gains — if the numbers stop growing, the tool has stopped working.
- Run the Headroom optimization proxy as a supervised local backend (`svc-headroom` on 127.0.0.1:8787) so the `headroom_compress`/`headroom_retrieve` MCP tools can actually store/retrieve compressed content and record savings. It is a **backend only** — no client's `ANTHROPIC_BASE_URL` is routed through it, so the Claude Desktop app (which force-overrides it, [headroom #869](https://github.com/headroomlabs-ai/headroom/issues/869)) is unaffected. Previously the MCP server was registered but had no backend, so it recorded no savings.
- Nudge Claude to use the headroom compression tools via a managed, idempotent block appended to the user's `CLAUDE.md` (removed automatically when `install_headroom` is disabled).

## 1.6 (07-07-2026)

- Fix default desktop launch failing when `install_headroom` is enabled (the default): the code rewrote the launch to `headroom wrap claude-desktop …`, but `headroom wrap` only supports coding-agent CLIs (`claude`, `codex`, ...) with arguments after `--`, so it produced an invalid command that left the app unlaunched. Leave the plain launch intact and instead register the `headroom` MCP server (`headroom mcp serve`) in Claude Desktop's config, exposing the `headroom_compress`/`headroom_retrieve`/`headroom_stats` tools inside the app. This is the supported headroom integration for Desktop, which overrides `ANTHROPIC_BASE_URL` so transparent proxy compression is not possible ([headroom #869](https://github.com/headroomlabs-ai/headroom/issues/869)). Disabling the option removes the entry again.
- Make the autostart resilient: if the launch command fails to start, fall back to the plain Claude Desktop launch so the app always comes up.

## 1.5 (07-07-2026)

- Change the default Claude Desktop data location to `/data/data`.
- Add Home Assistant smart context, Home Assistant MCP, and dangerous permission skip options.

## 1.4 (07-07-2026)

- Persist Claude Desktop sign-in: bundle gnome-keyring/libsecret/dbus-x11 and start an unlocked Secret Service in the desktop session, and launch with --password-store=gnome-libsecret. Fixes "Your sign-in won't be saved on this device. Install and unlock a system keyring". The keyring DB lives on persistent storage (/config/data), so the session survives restarts.

## 1.3 (07-07-2026)

- Fix startup crash loop ("All subprocesses terminated. Exiting."):
  - Make the Selkies desktop init oneshots (init-video, init-selkies-config) tolerant so a partially-permitted device/permission op in the HA sandbox no longer fails add-on bringup.
  - Pre-create /tmp/selkies_js.log so the base image's "chmod 777 /tmp/selkies*" calls never fail on an empty glob.
  - Reconcile XDG_RUNTIME_DIR to the tmpfs runtime dir instead of persistent storage.
- Run Claude Desktop with --disable-dev-shm-usage and drop the misplaced shm_size env var (Home Assistant ignores shm_size), fixing Electron renderer crashes on the default 64 MB /dev/shm.

## 1.2 (07-07-2026)
- Add baked-in git/GitHub CLI support with optional startup credential configuration.

- Fix Selkies startup by creating the s6 environment directory and XDG runtime directory before services start.

## 1.0 (07-07-2026)
- Minor bugs fixed
# Changelog

## 1.1

- Fix build failure: set HOME=/root when running rtk install script to ensure binary is installed to /root/.local/bin instead of /config/.local/bin (caused by LSIO base image overriding HOME)

## 1.0

- Fix build failure: remove separate `npm` apt package (already bundled in NodeSource nodejs)

## debianbookworm-1ae1f8ff-ls13

- Initial Claude Desktop add-on using LinuxServer Selkies, Home Assistant ingress, persistent sign-in data, runtime Claude Desktop updates, optional apt/pip additions, custom scripts, and bundled Claude Code optimization tools.
