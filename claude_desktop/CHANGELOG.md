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
