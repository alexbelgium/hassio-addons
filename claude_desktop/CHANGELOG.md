## 2026.08.04 (04-08-2026)
- Fix: reverted the GPU acceleration added in 2026.08.03. It did not just fail to help — it was
  what disabled the GPU. `--use-gl=angle --use-angle=gl-egl` forces Mesa's EGL X11 platform,
  which offers no window-capable EGLConfig under this Xvfb, so the GPU process logged
  `gl_surface_egl.cc:262 No suitable EGL configs found`, abandoned GL, and was relaunched with
  `--use-gl=disabled` while every renderer got `--disable-gpu-compositing`.
  Chromium already renders on the GPU here with no flags at all, because LSIO's Xvfb runs with
  `-vfbdevice /dev/dri/renderD128` and its GLX is therefore backed by the real render node —
  the premise that Xvfb offers only a software path was wrong for this base image. Measured
  three times, including at the production 15360x8640 screen: with the flags the GPU process
  loads `libEGL_mesa` and holds 1 fd on the render node; without them it loads `libGLX_mesa`,
  holds 8, and no renderer carries `--disable-gpu-compositing`.
  Removes `claude-gpu-probe` and the `gpu_acceleration` option. The probe was not wrong about
  the hardware, it was answering the wrong question: it exercised ANGLE's default GLX path,
  which works, and so it passed while the flags it gated disabled the GPU.
- Fix: `max_resolution` never did anything; the option is renamed to `MAX_RES`. It wrote
  `MAX_RES` into the s6 `container_environment`, but the base image's `svc-xorg` starts
  `#!/usr/bin/env bashio` rather than `with-contenv` and never reads that directory, so Xvfb
  kept starting at 15360x8640. Naming the option `MAX_RES` makes the add-on env layer inject
  it directly into every service `run` script, which is how `DRINODE` already reaches Xvfb.
  `MAX_RES` ships with no default, so nothing changes for anyone until it is set: the screen
  stays at the base image's 15360x8640. The old `max_resolution` default of `1920x1080` is
  deliberately not carried over — it had never taken effect, so shipping it now would have
  silently shrunk every existing desktop, including on 4K displays. Home Assistant drops
  options that are no longer in the schema (it logs a warning), so a saved `max_resolution`
  is discarded rather than migrated. The schema bounds each axis to 100-9999, which keeps the
  worst case (~400 MB of framebuffer) below the 15360x8640 default it replaces.
  Removes `22-display_tuning.sh`.
- Removed the amd64 GPU driver install, which has never run in any release. The 2026.08.03
  build corrected its gate variable but the guard is `if [[ ... ]]` and there is no `SHELL`
  directive, so it runs under dash, which has no `[[` — the condition was false and the `RUN`
  still exited 0. Verified in the shipped 2026.08.03 image: no `vainfo`, no
  `intel-media-va-driver-non-free`, and no matching install in its apt history.
  It was deleted rather than repaired, because it had nothing to add. Hardware OpenGL already
  works without it: the GPU process loads the Mesa gallium megadriver over DRI3 and holds 8
  fds on `/dev/dri/renderD128`, with no swrast/llvmpipe in the GL path. `libgl1-mesa-dri` and
  `mesa-vulkan-drivers` already come from the LSIO base at a newer backports version (Mesa
  25.0.7) than reinstalling them would give. And `intel-media-va-driver-non-free`, the one
  genuinely new payload, was installed live on the running add-on and changed nothing: VA-API
  failed identically to the free driver (`iHD_drv_video.so init failed`) on both
  `/dev/dri/renderD128` and `card0`. That failure is below the add-on, in the host i915 stack.
  Repairing the guard would have turned dead code into an untested apt transaction that swaps
  a base-image package for no measured benefit.
- A `[[` in the Dockerfile's legacy `/etc/services.d` shim is corrected to `[` for the same
  dash reason; that directory does not exist on this s6-overlay v3 base, so it is
  behaviour-neutral here.

## 2026.08.03 (03-08-2026)
- Performance: Claude Desktop now uses the GPU instead of rendering on the CPU.
  Under Xvfb, Chromium probed GLX, found only Xvfb's software path, and fell back to
  `--use-gl=disabled` + `--disable-gpu-compositing`, making the renderer the add-on's largest
  CPU consumer. It is now launched with `--ozone-platform=x11 --use-gl=angle --use-angle=gl-egl`,
  but only when the new `claude-gpu-probe` confirms Claude Desktop's own bundled ANGLE can
  create a hardware GL context on this host. New `gpu_acceleration` option (`auto`/`on`/`off`,
  default `auto`); any probe failure keeps the previous software rendering unchanged.
- Performance: new `max_resolution` option (default `1920x1080`) caps the virtual screen via the
  base image's `MAX_RES`. Xvfb previously ran at 15360x8640, so Xvfb and the Selkies capture
  loop tracked damage over a 133-megapixel area continuously, even with no browser connected.
  Selkies still resizes dynamically below the cap.
- Performance: Claude Code now talks to the Home Assistant MCP server over its native HTTP
  transport instead of through the `mcp-proxy` stdio bridge, removing one Python process per
  Claude Code session (~45 MB of private resident memory each). Claude Desktop keeps the
  bridge, as the config schema for a remote entry there is not confirmed.
- Performance: new `mcp_servers_desktop` / `mcp_servers_code` options select which MCP servers
  each client registers. Every stdio MCP server is a separate process per client, and Desktop
  starts another full set per Claude Code session it hosts. Defaults register all of them in
  both clients, i.e. the previous behaviour.
- Fix: the Dockerfile's Intel graphics block was dead code. It was gated on `TARGETARCH`, which
  the repo's builder does not pass, so it never ran: the shipped amd64 image has no `vainfo` and
  no `intel-media-va-driver-non-free`. It now uses `BUILD_ARCH`, and its Vulkan ICD check no
  longer names `intel_icd.x86_64.json`, a file Debian does not ship.
- Fix: stale Home Assistant MCP registrations (and the bearer token in them) are now removed
  from Claude Code's config when `enable_ha_mcp` is turned off. Ownership of an HTTP entry is
  recorded when the add-on writes it, so a manually configured `homeassistant` server is never
  claimed, overwritten, or deleted — not even when it sits on the default URL.
- `--disable-dev-shm-usage` is now applied only when `/dev/shm` is actually small (under
  256 MB). It is a workaround for Docker's 64 MB default, but Home Assistant ignores the add-on's
  `shm_size` so the real size varies per install; the size is now read at startup, keeping the
  crash workaround where it is needed and dropping it where it only pushed Chromium's shared
  memory into ordinary files. If the size cannot be determined, the flag is kept.

## 2026.08.02 (02-08-2026)
- Minor bugs fixed
 
## ubunturesolute-version-3a10bef7 (2026-08-01)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
 
## kali-version-e963b19b (2026-08-01)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
## 1.37 (28-07-2026)

- Fix the recurring "For your security, sign in again to keep using Claude." prompt for real. The v1.35 fix was ineffective: `--password-store=basic` was reaching the process (confirmed on a live install's `/proc/<pid>/cmdline`), yet the app kept logging `safeStorage not available, tokens will not persist` and `Encryption not available, returning empty env vars` on every launch. The missing half is an application-side opt-in — Electron refuses its built-in `basic_text` backend unless the app calls `safeStorage.setUsePlainTextEncryption(true)` before `ready`, and Claude Desktop never calls it (the symbol is present in the Electron binary but absent from `resources/app.asar`). So `isEncryptionAvailable()` stayed `false` and the auth token was never persisted, exactly as when the keyring backend was forced without a keyring daemon. Verified against a standalone Electron of the same generation: with `--password-store=basic` and no opt-in `isEncryptionAvailable()` is `false`; with the opt-in it is `true`, and a *separate later process* decrypts a blob written by an earlier one — which is the restart survival this add-on needs.
  - **The patch (`86-claude_safestorage.sh` + `claude-safestorage-patch.js`, new).** A small Node script injects that one opt-in call into the app's main bundle (`.vite/build/index.pre.js`) inside `app.asar`. Insertion is placed *after* the bundle's leading `"use strict";` rather than before it, because a directive prologue only takes effect as the first statement — prepending ahead of it would silently drop the entire main process out of strict mode. The archive is rebuilt rather than edited in place, since an asar's header stores a byte offset and length per file: entries flagged `unpacked` (which live in `app.asar.unpacked/`, not in the archive body) and symlink entries are carried through untouched, so the native-module layout is preserved, and the per-file SHA-256 `integrity` record is recomputed for the one file that changed. The injector fails closed: anything that does not open with an unambiguously terminated `"use strict"` directive is refused rather than patched by guesswork, since `"use strict" + x` is an expression and injecting into it would yield a syntax error. The rebuild is written to a temporary file, `fsync`ed, and then fully re-validated from disk — entry count, every offset and length parsed as an exact in-bounds integer, the last body ending precisely at EOF, and the patched entry's recomputed SHA-256 — before it is renamed over the original and the directory synced; the temporary file is removed on every failure path. So a torn, truncated or short write can never replace a working archive. Verified byte-for-byte against the real archive: same 211 entries, no `unpacked`/symlink flag drift, no trailing slack, every integrity hash valid, and content differing in exactly one file.
  - **Why it re-runs every boot.** `81-claude_update.sh` apt-upgrades `claude-desktop` on startup, and a new package ships a fresh, unpatched `app.asar`; a one-shot patch at image build time would therefore be undone by the first update. The script is marker-guarded, so a boot where the app did not change is a no-op, and it is numbered `86-` to land after both the update check and `85-openbox_autostart.sh`, while still completing before any s6 service — i.e. before the desktop launches the app. A failure is logged and swallowed rather than propagated, and the patcher is run under a 120s `timeout`: an unpatched app still runs, it just forgets the sign-in, which is not worth blocking startup over. The hook ends in an explicit `exit 0` so no logging branch can turn a non-fatal patch failure into a failed cont-init, and it sweeps stale temporary archives itself — `timeout` kills the patcher outright, so the run that hits the cap cannot execute its own cleanup, and each stranded file is archive-sized.
  - **`gnome-keyring` stays out of the image.** Re-adding it would reintroduce the first-boot keyring password prompt that blocks Claude Desktop from launching at all. This route needs no keyring, no D-Bus Secret Service, no daemon and no password, so no prompt can appear. The trade-off is unchanged from v1.35 and is inherent to the `basic` backend: its key is fixed rather than gated by a keyring, so any process that can read the persistent `$HOME/.config/Claude` profile can recover the stored credentials.
  - **One-time step after upgrading.** The previously stored session is already stale, so a single sign-in is still needed once after this update; it then persists across restarts.

 
## 1.36.4 (28-07-2026)

- Fix Selkies dying with a Rust `RuntimeDirNotSet` unwrap panic just after `Data WebSocket Server listening on port 8081`, and the data websocket then being proxied to the wrong port. Upstream relies on s6-rc ordering: `init-selkies-config` publishes `XDG_RUNTIME_DIR` and `CUSTOM_WS_PORT` into the s6 envdir and `svc-selkies` starts afterwards. The add-on entrypoint replaces s6-overlay and starts every `s6-rc.d` run script in parallel with no dependency graph, so Selkies can snapshot the envdir before that oneshot has written to it -- which is why it bound port 8081 (its own default) instead of the 8082 nginx proxies to, and why its Wayland compositor found no runtime directory to bind a socket in. `20-folders.sh` now exports both variables inside each run script, where no start ordering can lose them, and corrects the base image's `$HOME/.XDG` override where that write happens instead of appending a correction after the `exit 0` that the oneshot-tolerance block adds -- which meant the correction never ran on any boot after the first.

## 1.36.3 (28-07-2026)

- Make the Selkies startup scripts add-on agnostic so `webtop` and `webtop_kde` can share them by symlink instead of carrying their own drifted copies. `20-folders.sh` now derives its default data location from the home directory the Dockerfile baked into the `abc` user (`getent passwd abc`) rather than hardcoding `/data/data`, and the `permission_mode: bypass` root guard is skipped on add-ons that do not declare that option. `80-configuration.sh` falls back to `pip` when the image does not ship `uv`. No behaviour change for Claude Desktop: `getent passwd abc` returns `/data/data`, which is exactly the value that was hardcoded before.

## 1.36.2 (28-07-2026)
- Minor bugs fixed
 
## 1.36.1 (27-07-2026)

- Fix the Codex CLI install failing on every boot with `Verified Codex <version> installation failed; Codex is unavailable this boot`, leaving `install_codex_cli` permanently non-functional. The download, its SHA-256 verification, and the extraction all succeeded; the chain broke at the final step, which validates the candidate binary by running `--version` as the `abc` runtime user. `mktemp -d` creates its directory `0700 root:root`, and `abc` cannot traverse a root-only directory, so executing the staged binary failed with `unable to exec: Permission denied` (exit 126) before it could be moved into place. Reproduced and fixed by making the staging directory traversable (`chmod 0755`) immediately after `mktemp`; verified on a live add-on container, where the same probe goes from exit 126 to success once the mode is widened. Nothing secret is staged there — the public release archive and the extracted binary, both world-readable upstream artifacts — and the existing `cleanup()` trap still removes the directory on exit. The validation deliberately keeps running as `abc` rather than root, so the binary is exercised as the identity that will actually run it.

## 1.36 (27-07-2026)

- Add optional OpenAI Codex CLI support, so a Claude session in this add-on can delegate work to ChatGPT Codex. Three parts: an `install_codex_cli` switch, a browserless way to activate a ChatGPT subscription on it, and an MCP registration that makes Codex callable as a tool from Claude.
  - **Install (`install_codex_cli`, default off).** Codex is deliberately *not* baked into the image: the Linux release binary is ~310 MB extracted, which is not worth carrying in every installation for an off-by-default option, and updating it would then require an add-on rebuild. The new `81-codex_cli.sh` cont-init script downloads the pinned static-musl release (`ARG`/`ENV CODEX_VERSION`, currently `0.145.0`) into `/data/codex/bin` and symlinks it onto `PATH`. `/data` is the add-on's own persistent volume — independent of the configurable `data_location` — so the ~113 MB download happens once, not per boot and not again after an add-on update unless the pinned release changes. The install prefix is outside `$HOME` on purpose: the managed-MCP merge in `82-claude_tools.sh` treats any server `command` under `$HOME` as user-installed and refuses to manage it, so an add-on-owned binary living there could never be updated or removed by the add-on. The download fails open like the Claude Desktop update check — an offline boot, a GitHub outage or a bad pin logs a warning and leaves any existing binary in place instead of aborting startup, and the new binary is validated by actually running `--version` from the staging directory before it replaces the current one, so a truncated download can never overwrite a working install. Staging deliberately happens under `/data` rather than the default `/tmp`: `/tmp` in this image is a RAM-backed tmpfs, so holding the 110 MB archive plus the 310 MB binary there during boot is a real risk on a small Home Assistant host, and it is mounted `noexec`, which would make the validation step impossible anyway. Staging on the destination filesystem also turns the final move into an atomic rename instead of a second 310 MB copy. Disabling the option is non-destructive: the binary and the completed sign-in are kept, so a disable/re-enable cycle needs neither another download nor another login.
  - **Subscription activation (`codex-login`).** Codex's default sign-in serves an OAuth callback on `localhost:1455` and expects a local browser, which cannot work here — the image ships no browser, and the add-on is reached through Home Assistant ingress. The new `/usr/local/bin/codex-login` helper runs `codex login --device-auth` instead, the flow OpenAI documents for headless machines: it prints a verification URL and a short-lived one-time code to approve on any other device, then polls until done. It can be run from the desktop's xterm (openbox right-click menu), from a Claude Code session, or from the container console, and it drops to the `abc` runtime user first so `~/.codex/auth.json` is not created root-owned — the same failure mode `83-github_cli.sh` documents for `~/.gitconfig`. Output is line-buffered so the URL and code appear immediately even without a TTY. If a session is already authenticated the helper reports the account and exits rather than starting a second flow. Credentials live in the persistent home, so the sign-in survives restarts and updates.
  - **MCP bridge.** `codex mcp-server` exposes Codex itself as a stdio MCP server (tools `codex` and `codex-reply`, verified by driving the 0.145.0 binary over stdio), which is registered through the *existing* managed-MCP merge in `82-claude_tools.sh` rather than a second copy of that logic — so it inherits the merge's idempotence, its refusal to clobber a user-customized entry, its removal-when-disabled behaviour, and the `0600` re-tightening of the token-bearing config files. Registration covers both Claude Code (`~/.claude.json`) and Claude Desktop, so every session type gets the tool. A managed `CLAUDE.md` block tells Claude what Codex is and when a second agent is worth the round-trip, since registering a server without guidance rarely gets it used — the same gap the Headroom block exists to close.
  - **Sandbox (`codex_sandbox_mode`, default `danger-full-access`).** Codex normally confines itself with a Linux OS sandbox (Landlock, or its bundled bubblewrap), which is unreliable inside a Home Assistant add-on container — and the container is already the security boundary. The default therefore bypasses Codex's own sandbox; `read-only` and `workspace-write` remain selectable. The chosen mode is applied in two places that are kept in sync: as root-level `-c` config overrides in the MCP registration (Codex forwards those to the MCP server, and they must precede the subcommand), and as a managed block at the top of `~/.codex/config.toml` so plain terminal `codex`/`codex exec` runs behave the same. That block is written at position 0 rather than appended, because a bare TOML key placed after a `[table]` header would silently become a key *of that table*. `approval_policy` is always `never` — an MCP- or cron-driven run has nobody to answer a prompt. Claude Code's own permission prompts still gate every `mcp__codex__*` call unless `permission_mode` is `bypass`.
  - `84-claude_runtime_ownership.sh` now also reconciles `~/.codex`, and `claude-tools-doctor.sh` reports the Codex binary, the installed-versus-pinned version, the two new switches, and the login status (which prints the auth mode, never the token).

## 1.35 (23-07-2026)

- Fix recurring "For your security, sign in again to keep using Claude." and the Claude app's dispatch tab showing this desktop as offline when opened from mobile first. Root cause (confirmed from `~/.config/Claude/logs/main.log` on a live install): the app launches with `--password-store=gnome-libsecret`, forcing Electron's libsecret/Secret-Service backend, but `gnome-keyring` was removed from the image in a previous commit because it prompted for a keyring password on first boot and blocked the app from launching. With the flag still forcing libsecret and no keyring daemon running, `safeStorage.isEncryptionAvailable()` is `false` — logs showed `session will not persist; app secrets fall back to plaintext` and `cannot store allowlist cache`. The un-persisted session then goes stale, failing the elevated-access OAuth check (`session_stale_relogin`) that the cowork/dispatch bridge needs, so the bridge is "parked until re-login" — which is what the Claude app surfaces as the desktop being offline, until a fresh sign-in (only completable from a computer, see `SIGN_IN.md` Problem A) un-parks it. `rootfs/defaults/autostart` now launches with `--password-store=basic` instead: Electron's built-in fixed-key store needs no daemon and never prompts, and persists under `$HOME/.config/Claude` (`/data/data`, persistent), so the session survives restarts and dispatch stays online regardless of which device connects first. A passwordless keyring was considered and rejected — it would live in the same persistent volume as the ciphertext, adding no real protection in this single-user self-hosted setup. `Dockerfile`'s stale comment (still describing gnome-keyring as installed) is corrected; the package stays removed.
  - New `85-openbox_autostart.sh`: the app is actually launched from the *persistent* `$HOME/.config/openbox/autostart`, which the base image's `init-selkies-config` oneshot only seeds from `/defaults/autostart` when the persistent copy is missing — so on any existing install, editing `/defaults/autostart` alone would never reach the file actually being run. This new cont-init script re-syncs the persistent copy from the image on every boot (as root, before any s6-rc service starts, so it also overwrites a copy a prior boot may have left root-owned/read-only under `RESTART_APP`), so the `--password-store` change (and any future autostart change) reaches existing installs on upgrade, not just fresh ones.
  - One-time step after upgrading: the previously-stored session is already stale, so complete one sign-in from a computer (mobile cannot complete the OAuth flow in the streamed desktop, see `SIGN_IN.md` Problem A). The session then persists normally.
- Fix `21-gpu_permissions.sh` failing at boot (`exiting 2`) while working fine when re-run manually. Root cause: the script runs under bashio, which sets `set -o pipefail`, together with the script's own `set -e`; `getent group "$gid" | awk ...` exits 2 whenever `$gid` has no named group yet, which is the normal case here because this script deliberately runs *before* the base image's `init-video`/`init-adduser` have named the passed-through `/dev/dri` gids. That exit 2 aborted the script immediately, before reaching its own `-z "$gname"` fallback (written specifically to create a `dri<gid>` group for exactly this unnamed case) — and, as a side effect, before the `chmod o+rw` fallback further down, so the boot-time GPU-permission hardening from 1.31 wasn't fully applied either. A manual re-run afterward always "worked" because by then `init-video` had already named the group. Fixed by not letting that expected exit propagate: `gname="$(getent group "$gid" | awk -F: '{print $1}')" || gname=""`. The fallback now also distinguishes the expected exit 2 (unnamed GID) from any other `getent` failure, logging a warning instead of silently treating unrelated NSS/database errors the same way.
- `SIGN_IN.md` now states explicitly that the `basic` password store trades away OS-backed at-rest protection for the persisted session.

## 1.34 (22-07-2026)

- Reduce idle and active remote-desktop overhead without changing Claude Desktop, Claude Code, GPU acceleration, Headroom, RTK, or TokenSave behavior. Selkies now defaults to 15 FPS instead of 30 FPS, uses browser-rendered cursors, and disables unused audio, microphone, gamepad, second-screen, and collaborative-sharing channels. All settings remain overridable through `env_vars` for installations that need those features.
- Explicitly install and build-validate the Intel userspace graphics stack in the amd64 image for Intel N150/Twin Lake and other modern Intel iGPUs: `intel-media-va-driver` for VA-API encoding/decoding, `libgl1-mesa-dri` for the Mesa Iris OpenGL driver, `mesa-vulkan-drivers` for Intel Vulkan, and `vainfo` for runtime diagnostics. The host-provided `i915` kernel driver and existing `/dev/dri` device mapping remain unchanged.

## 1.33 (22-07-2026)

- Add cowork virtualization support: `qemu-system-x86` and `ovmf` (Bookworm main, installed via apt) plus `virtiofsd` for sharing the workspace into the sandbox microVM. `virtiofsd` is only packaged for Debian trixie/sid, not Bookworm or bookworm-backports, and its trixie `.deb` links a newer GLIBC than this add-on's Bookworm runtime — so it now gets built from the pinned crates.io release (`1.14.0`) in a dedicated `virtiofsd-builder` stage, the same GLIBC-safe pattern already used for `rtk` and `tokensave`. Its build deps (`libseccomp-dev`, `libcap-ng-dev`, `pkg-config`, `clang`, `libclang-dev`) live only in that builder stage; only the runtime shared libs (`libseccomp2`, `libcap-ng0`) ship in the final image. The built binary is validated with `--version` at build time alongside `rtk`/`tokensave`, so a GLIBC/ABI mismatch fails the image build instead of surfacing at container start. Docker itself is deliberately not installed: this base image already ships Docker-in-Docker (`docker-ce`/`containerd.io` from Docker's own apt repo, started via the pre-existing `START_DOCKER` env var) — an initial attempt to also `apt-get install docker.io` broke the build, since Debian's package pulls in `containerd`/`runc`, which apt refuses to install alongside the base image's already-installed `containerd.io` (`Conflicts`).
 
## ubunturesolute-version-8208e985 (2026-07-21)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
 
## kali-version-9ad48e7a (2026-07-18)
- Update to latest version from linuxserver/docker-baseimage-selkies (changelog : https://github.com/linuxserver/docker-baseimage-selkies/releases)
## 1.32 (17-07-2026)

- Bump `tokensave` from 7.2.0 to 7.4.0 (`rtk` was already pinned to its current latest GitHub release, `v0.43.0`; `headroom-ai` is intentionally installed unpinned from PyPI, so it already tracks latest at every build and had nothing to bump). Reviewed the intervening 7.3.0/7.4.0 release notes against every tokensave surface this add-on drives (`install --agent claude --git-hook yes`, `uninstall --agent claude`, `sync`, `init`, `doctor --agent claude`, `gain --all --range 30d`, and the `mcp__tokensave__*` tool set granted in `settings.json`): no flag, output shape, or MCP tool name used here changed. Directly relevant fixes carried along: `tokensave sync` auto-migrates a v12 database (missing the trait-dispatch caller cache) to v13 as a normal part of syncing, which the add-on's corruption-quarantine logic won't mistake for corruption since the schema migration doesn't produce a "malformed"/"not a database" error; and `install`/`uninstall`'s JSON writer now resolves a symlinked `~/.claude/settings.json` before its atomic rename instead of replacing the symlink with a plain file, so a dotfiles-managed settings file survives untouched.
- Fix startup TokenSave repository preparation silently doing nothing: both `81-tokensave_repositories.sh` and the indexing loop in `82-claude_tools.sh` read `tokensave_project_paths` through `done < <(bashio::config ...)`, but `bashio::config` begins with a `read -d ''` heredoc that always returns non-zero, and a process substitution inherits the `errexit` enabled by the bashio wrapper itself — so the subshell died before printing and every boot iterated over an empty list (no `safe.directory` persistence, no startup `sync`/`init`; command substitutions were unaffected because subshells drop `errexit` when `inherit_errexit` is off, which is why every other option lookup worked). Repositories only got indexed when tokensave's own git hooks or a manual `tokensave init` happened to run. The list is now captured with a command substitution first and the loop reads from the captured variable (here-string); same fix applied to `claude-tools-doctor.sh`. The indexing loop also moved ahead of the MCP-registration merge, and the merge now re-tightens the 0600 mode on the token-bearing configs even on no-change boots — a first-time `tokensave init` rewrites `~/.claude.json` itself at default permissions, which previously could leave the stored Home Assistant token world-readable until the next registration change.
- Simplification pass over the startup logic: every remaining line now serves a live purpose, with no change to what gets configured — Headroom (proxy routing, MCP registration, CLAUDE.md guidance, PostToolUse auto-compression, dashboard exposure), RTK (global files + PreToolUse hook), and TokenSave (full agent integration + per-repo indexing) are still applied automatically to every new session type (terminal, Desktop cowork/dispatch, cron).
  - `82-claude_tools.sh`: the three hand-rolled `~/.claude/settings.json` hook mutators (rtk add, rtk remove, headroom PostToolUse) are replaced by one shared `manage_settings_hook` helper using the proven strip-then-re-append pass (same dedup/matcher-migration semantics; additionally no longer creates an empty `settings.json` when asked to remove a hook from a machine that never had one). The two copy-pasted CLAUDE.md guidance managers (headroom, ha-api-helper) collapse into one `manage_claude_md_block` helper producing byte-identical blocks, so existing installs are recognized without a rewrite.
  - `81-tokensave_repositories.sh` is merged into the TokenSave loop of `82-claude_tools.sh`: the same path list was parsed twice with identical trimming/validation only so `safe.directory` could be persisted before repository detection ran as root. Detection now runs directly as the runtime user with a one-shot `safe.directory` override (the persisted entry is still written for tokensave's git hooks and Claude sessions), removing the duplicate loop and the root-reads-abc-gitconfig coupling. The battle-tested defensive sync/init block (flock, retries, corruption quarantine, init sentinel) is unchanged.
  - The `/tmp/claude-desktop-command` indirection is gone: `82-claude_tools.sh` wrote the default launch command to a file that only `defaults/autostart` read, with the identical default hardcoded as its fallback — nothing else ever wrote it. `autostart` now launches Claude Desktop directly (keyring bootstrap unchanged).
  - `82-claude_tools.sh` no longer ends with its own recursive chown of `~/.claude`, `~/.claude.json`, and `~/.config/Claude`: `84-claude_runtime_ownership.sh` already reconciles exactly those paths after all Claude configuration scripts have run.
  - `83-claude_permissions.sh` drops the hidden `.addon-permission-mode.json` state file in favor of the same managed-value semantics used for `ANTHROPIC_BASE_URL`: `auto`/`bypass` set `permissions.defaultMode`, `strict` removes it only while it still holds an add-on-managed value (`auto`/`bypassPermissions`), and a hand-set custom value is never deleted. The old restore-from-state behavior could resurrect a stale value recorded on the first managed boot; the stale state file is cleaned up on upgrade.
  - `80-configuration.sh` sheds branches that were unreachable in this image: `apk`/`pacman` installers (the base is Debian), the `pip3` fallback (`uv` is always baked in), and the no-op timezone error path (invalid `TZ` values are now actually detected against `/usr/share/zoneinfo` before the symlink is written).
  - Remove the dead `auto_update` option from `config.yaml` and the README: its schema entry was removed back in 1.22 and `81-claude_update.sh` has updated Claude Desktop unconditionally (best-effort, offline-safe) ever since; the README now states that behavior instead of documenting a switch that did nothing.

## 1.31 (16-07-2026)

- Pin the LinuxServer selkies base image to a fixed version (`…-debianbookworm-45960cc3-ls113`) instead of the rolling `…-debianbookworm` tag. The rolling tag is rebuilt continuously (and itself installs selkies "latest" at base-build time), so the desktop/stream runtime could change under the add-on with no change to its own files — builds are now reproducible and the base only moves when this value is bumped deliberately. The pinned tags resolve to exactly the image the rolling tag currently points at (amd64 `sha256:6a4d5154…`, aarch64 `sha256:90914dfd…`).
- Fix Claude Desktop never appearing — the Selkies web client stayed on "waiting for stream" forever with `libEGL warning: failed to open /dev/dri/card0: Permission denied` in the log. The LinuxServer base image grants the desktop user (`abc`) access to the `/dev/dri` render nodes in its `init-video` s6 oneshot, but that oneshot is not a dependency of `svc-xorg`/`svc-selkies`/`svc-de`, so on Home Assistant those long-running services regularly start (via `s6-setuidgid abc`) *before* `abc` has been added to the render group. Xorg/Selkies/pixelflux then open the render device without permission, the video pipeline produces no frames, and the stream never starts. Prepare the exposed DRI nodes in a new `21-gpu_permissions.sh` cont-init script instead: `cont-init.d` runs to completion before any s6-rc service starts, so `abc` is added to each node's owning group (and the node is made world read/write as a timing-independent fallback) in time for the graphical services to use the GPU. Best-effort and a no-op on hosts that expose no GPU.

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
