# Home assistant add-on: Claude Desktop

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Project Maintenance][maintenance-shield]

Run Claude Desktop in a LinuxServer.io Selkies add-on, with Headroom context
compression, RTK Bash-output acceleration, and TokenSave semantic code
intelligence wired in by default.

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install **Claude Desktop**.
3. Start the add-on and open the web UI from the sidebar.
4. Sign in with your Claude account from the Desktop app.

Claude Desktop sign-in requires a claude.ai plan that supports the Desktop app.
API keys are not accepted by the Desktop application. Anthropic's Linux beta
currently does not include Computer Use or dictation.

## Architecture

Everything is built around the Claude Desktop app. Claude Code is installed in
the same image but is not exposed as a standalone service: Claude Desktop's
cowork and dispatch sessions run it internally, and they pick up the shared
Claude Code configuration (`~/.claude`), hooks, MCP servers, permissions, and
PATH tools.

- **Claude Desktop** uses Headroom through its MCP tools.
- **Claude Code sessions inside Desktop** get the same MCP servers, permission
  mode, and RTK/TokenSave hooks through the shared Claude Code configuration.
- PATH-based Claude Code launches are routed through the supervised Headroom
  proxy when `headroom_wrap_claude_code` is enabled. If a Desktop release calls
  `/usr/bin/claude` directly, the session remains functional and still has the
  shared permission mode and Headroom MCP tools, but transparent proxy
  compression cannot be injected.
- The shared `abc` desktop account runs under the configured `PUID`/`PGID`
  (default `1000:1000`). When `permission_mode: bypass` is selected while
  `PUID` is `0`, the add-on automatically falls back to UID `1000` before
  Selkies and Claude Desktop start, because Claude Code refuses bypass mode
  under an effective root UID.
- **gnome-keyring** provides the Secret Service backend Electron needs to
  persist sign-in and dispatch permission grants across restarts.

## Optimization layers

The three bundled optimization tools are complementary:

- **RTK** rewrites supported Bash commands so Claude receives compact output.
- **TokenSave** builds a local semantic graph for explicitly selected code
  repositories and steers Claude away from repeated Explore/Grep/Read fan-out.
- **Headroom** transparently compresses proxied Claude Code traffic and also
  exposes on-demand compress/retrieve/statistics MCP tools to Claude Desktop.

TokenSave's complete Claude integration is installed at startup: MCP server,
permissions, PreToolUse/UserPromptSubmit/Stop hooks, global prompt rules, and
Git synchronization hooks. A repository is indexed only when it is listed in
`tokensave_project_paths`; no automatic filesystem scan is performed.

## Features

- Claude Desktop in single-app Selkies mode with Home Assistant ingress.
- Official Claude Code stable package powering Desktop cowork/dispatch
  sessions.
- Persistent `$HOME` at the configured `data_location` (default `/data/data`),
  preserving Desktop and Claude Code state across restarts.
- Persistent sign-in through a bundled, auto-unlocked gnome-keyring.
- Configurable Claude Code permissions: strict prompts, automatic safe-action
  approval, or explicit full bypass for trusted installations.
- Automatic non-root runtime enforcement for bypass mode, including root-console
  wrapper launches.
- Best-effort Claude Desktop update from Anthropic's apt repository at every
  startup (skipped silently when offline).
- Optional extra apt and pip package installation (pip installs use `uv`).
- Baked-in `git`, GitHub CLI (`gh`), `ripgrep`, `jq`, `shellcheck`, `yamllint`,
  `hadolint`, and `actionlint`.
- Custom script support through the repository standard `claude_desktop.sh`.
- Bundled optimization tools: Headroom, RTK, and TokenSave; Caveman remains
  available as an opt-in plugin.
- Optional OpenAI Codex CLI, authenticated exclusively with a ChatGPT
  subscription and reachable from Claude through the native Codex MCP server.
- Optional Home Assistant MCP bridge so Claude can query and control Home
  Assistant.
- Independent hourly savings reports for Headroom, RTK, and TokenSave.
- `claude-tools-doctor.sh` diagnostics for binaries, routing, hooks, MCP
  registrations, project indexes, proxy health, permissions, runtime identity,
  and gains.
- Low-power defaults for GPU mapping, Selkies frame rate, and volatile caches.

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `PUID` / `PGID` | `1000` / `1000` | Numeric user and group of the shared `abc` desktop account that owns the data location and runs Claude Desktop. In bypass mode, a root `PUID` is automatically replaced at runtime by UID `1000` while the configured group is retained. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `gpu_acceleration` | `auto` | Whether Claude Desktop renders on the GPU. `auto` adds Chromium's ANGLE/EGL flags only when a probe confirms a hardware GL context is available, `on` forces them without probing, `off` keeps software rendering. Use `on` with care: it skips every safety check, so on a host that cannot actually drive those flags the desktop can come up black — set the option back to `auto` or `off` to recover. |
| `max_resolution` | `1920x1080` | Caps the virtual screen. Selkies still resizes dynamically below this; raise it only if you drive the desktop from a larger display. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `permission_mode` | `auto` | Claude Code permission policy: `strict`, `auto`, or `bypass`. |
| `install_headroom` | `true` | Register Headroom MCP and run the supervised local proxy. |
| `headroom_wrap_claude_code` | `true` | Route PATH-based Claude Code launches through the already-running Headroom proxy. |
| `headroom_auto_compress` | `true` | Auto-compress large tool outputs in every Claude Code session via a managed `PostToolUse` hook. |
| `expose_headroom_dashboard` | `false` | Bind Headroom to all interfaces. Port `8787/tcp` must also be mapped manually. |
| `install_rtk` | `true` | Configure RTK's Claude Code `PreToolUse` Bash hook. |
| `install_tokensave` | `true` | Install TokenSave's complete global Claude integration. |
| `tokensave_project_paths` | `[]` | Explicit absolute Git repository paths to initialize or sync at startup. |
| `mcp_servers_desktop` | all | Which managed MCP servers Claude Desktop registers (`headroom`, `tokensave`, `homeassistant`, `codex`). |
| `mcp_servers_code` | all | Which managed MCP servers Claude Code registers. Each stdio server is a separate process per client, and Desktop starts another set per Claude Code session it hosts, so trimming this is the cheapest way to cut memory. |
| `install_caveman` | `false` | Install the third-party Caveman Claude Code plugin at startup. |
| `install_codex_cli` | `false` | Install the latest stable OpenAI Codex CLI at startup and register its native MCP server so Claude can delegate work to ChatGPT Codex. |
| `codex_sandbox_mode` | `workspace-write` | Filesystem scope Codex runs with: `read-only`, `workspace-write`, or `danger-full-access`. |
| `enable_tools_health_report` | `true` | Write independent Headroom, RTK, and TokenSave gains to the add-on log hourly. |
| `install_github_cli` | `true` | Enable setup checks for the baked-in `git` and `gh` commands. |
| `github_token` | | Optional GitHub token used to authenticate `gh` and Git operations. |
| `github_username` | | Optional global Git author name. |
| `github_email` | | Optional global Git author email. |
| `enable_ha_mcp` | `false` | Register Home Assistant's MCP server in Claude (requires `ha_mcp_token`). |
| `ha_mcp_url` | `http://homeassistant:8123/api/mcp` | Streamable HTTP endpoint of Home Assistant's MCP Server integration. |
| `ha_mcp_token` | | Home Assistant long-lived access token used by the MCP bridge. |
| `enable_ha_api_helper` | `true` | Ship the `ha-cli` Core-API helper and add guidance so Claude can configure Home Assistant without a `/config` mount. |
| `additional_apps` | | Comma-separated Debian apt packages to install at startup. |
| `additional_pip` | | Comma-separated pip packages installed at startup (via `uv`). |
| `data_location` | `/data/data` | Persistent home directory for Claude and tooling. |
| `env_vars` | `[]` | Additional environment variables exported inside the container. |

### Permission modes

```yaml
permission_mode: auto
```

- `strict` keeps Claude Code's normal interactive permission prompts.
- `auto` asks Claude Code's automatic permission classifier to approve safe
  operations while retaining prompts for risky actions. This is the default.
- `bypass` disables Claude Code permission checks by using
  `bypassPermissions` in the shared settings and
  `--dangerously-skip-permissions` for wrapper-launched sessions.

Claude Code does not permit bypass mode when its effective UID is `0`. If the
add-on is configured with `PUID: 0`, selecting `bypass` runs the shared `abc`
runtime account as UID `1000` instead, before storage ownership and Desktop
startup. Its configured primary GID is retained, so group-based access to
mounted Home Assistant paths remains available. Strict and auto modes keep the
configured identity unchanged.

A root shell invoking `/usr/local/bin/claude` in bypass mode is also dropped to
the remapped `abc` account. Directly invoking `/usr/bin/claude` as root still
bypasses the add-on wrapper and will be rejected by Claude Code.

`bypass` gives Claude broad authority over all mounted writable data and every
command or credential available inside the add-on. Enable it only in a trusted
installation with trusted repositories and mounts. Mounted paths must remain
accessible to the effective non-root UID or its retained group.

### TokenSave project example

Only repositories listed here are indexed. Paths must be absolute, mounted in
the add-on, and resolve to a Git working tree:

```yaml
tokensave_project_paths:
  - /share/projects/hassio-addons
  - /share/projects/birdnet-go
```

At startup, an uninitialized repository receives `tokensave init`; an existing
index receives an incremental `tokensave sync`. Removing a path from the option
stops automatic synchronization but does not delete its `.tokensave` database.
Configured repositories are added to Git's `safe.directory` list for the shared
runtime user before TokenSave performs repository discovery.

## Headroom behavior

When `install_headroom` is enabled, the add-on registers `headroom mcp serve`
with the explicit local proxy URL in Claude Desktop and Claude Code, then starts
a supervised Headroom backend on `127.0.0.1:8787`.

Claude Desktop overrides `ANTHROPIC_BASE_URL`, so Desktop chat deliberately uses
the MCP integration. The `/usr/local/bin/claude` wrapper routes PATH-based Claude
Code sessions through `headroom wrap claude --no-proxy`, reusing the supervised
backend without starting a second proxy.

With `headroom_auto_compress` enabled (the default), a managed Claude Code
`PostToolUse` hook additionally compresses large `Bash`/`Grep`/`Glob`/`WebFetch`
outputs (over ~4000 characters) in **every** session type — terminal, Desktop
cowork, dispatch, and cron — without the model having to remember to call the
MCP tools. The original output is kept in Headroom's local store for one hour
and can always be recovered with `mcp__headroom__headroom_retrieve` using the
hash printed in the compression marker. Error text (`stderr`) is never
compressed, and plain prose passes through unchanged; the savings come from
structured output such as JSON dumps, search results, and logs.

The dashboard is disabled externally by default. To expose it:

1. Set `expose_headroom_dashboard: true`.
2. Map `8787/tcp` in the add-on **Network** section.
3. Open `http://<home-assistant-host>:8787/dashboard`.

The dashboard is unauthenticated. Do not publish this port to the public
internet.

## Codex CLI

Setting `install_codex_cli: true` adds OpenAI's Codex CLI alongside Claude and
registers `codex mcp-server` in both Claude Code and Claude Desktop. A Claude
session can therefore delegate a task to ChatGPT Codex and read its result back
through MCP.

Codex is not baked into the image because its Linux binary is large and the
feature is off by default. At each startup, the add-on resolves the latest
stable upstream release. It downloads the architecture-specific binary into
persistent `/data/codex/bin` only when the installed release is missing or
outdated, verifies the GitHub-published SHA-256 digest before extraction or
execution, validates the staged binary with `--version`, and replaces the
existing binary atomically. If release metadata or the download is unavailable,
startup continues and a previously working installation is retained.

### Signing in with a ChatGPT subscription

The add-on has no browser, so use the bundled device-code helper:

```bash
codex-login
```

Run it from the desktop's xterm, a Claude Code session, or the container
console. It prints a verification URL and one-time code that you approve on
another device. Credentials are stored in the runtime user's persistent
`~/.codex/auth.json`, so the sign-in survives restarts and add-on updates.

This integration is deliberately **subscription-only**. The managed launcher
removes any inherited `OPENAI_API_KEY` and starts every Codex command—including
`codex mcp-server`—with:

```toml
forced_login_method = "chatgpt"
cli_auth_credentials_store = "file"
```

The launcher also removes caller-provided overrides for those two keys before
starting Codex. The same values are maintained in `~/.codex/config.toml`.
Consequently, the MCP server uses the ChatGPT Codex entitlement and cannot
silently fall back to usage-based OpenAI API-key billing.

### Using Codex from Claude

Claude receives two native MCP tools:

- `mcp__codex__codex` starts a task. Pass a self-contained `prompt` and set
  `cwd` to the repository Codex should inspect. The result includes a
  `threadId`.
- `mcp__codex__codex-reply` continues the same Codex thread with its
  `threadId`.

The add-on also installs managed Claude guidance recommending Codex for
independent review, a second diagnosis, or a competing implementation rather
than routine lookups. Codex consumption counts against the signed-in ChatGPT
plan's Codex allowance.

### Sandbox scope

`codex_sandbox_mode` defaults to `workspace-write`, allowing implementation
inside the supplied repository without granting unrestricted access to every
mounted path. Select `read-only` for review-only delegation. Use
`danger-full-access` only as an explicit fallback when Codex's nested Linux
sandbox is unavailable in the Home Assistant add-on container and the mounted
paths are trusted.

`approval_policy` is always `never`, because an MCP-driven Codex process has no
interactive operator to answer a prompt. Claude Code's own permissions still
gate the `mcp__codex__*` call unless `permission_mode` is `bypass`.

## Diagnostics

Run the following inside the add-on through a custom script or container console:

```bash
claude-tools-doctor.sh
```

The report checks the tool binaries, configuration switches, configured and
effective runtime identities, redacted MCP registrations, Claude hooks,
permission mode, Headroom health, TokenSave indexes, routing, and recorded
savings. It never prints MCP environment values or raw Codex authentication
status because either can contain credentials or masked credential fragments.

The hourly report can also be invoked manually:

```bash
claude-gains-report.sh
```

## Home Assistant MCP bridge

To let Claude query and control Home Assistant:

1. In Home Assistant, add the **Model Context Protocol Server** integration
   (Settings → Devices & services → Add integration).
2. Create a long-lived access token (your profile → Security).
3. Set `enable_ha_mcp: true` and paste the token into `ha_mcp_token` in the
   add-on configuration, then restart the add-on.

The add-on bridges Claude to the integration's stateless Streamable HTTP
endpoint (`/api/mcp`) with `mcp-proxy`. Override `ha_mcp_url` only if your Home
Assistant instance is not reachable as `homeassistant:8123` from add-ons.

## Configuring Home Assistant (API helper)

When `enable_ha_api_helper` is on (the default), the add-on ships a `ha-cli`
command and tells Claude — via a managed block in `~/.claude/CLAUDE.md` — that
it can configure Home Assistant through the Home Assistant **Core API** rather
than a filesystem mount. This is deliberately more contained than mapping
`/config`: the API cannot read `configuration.yaml`, `secrets.yaml`, or any
other add-on's stored credentials.

`ha-cli` authenticates automatically with the add-on's `SUPERVISOR_TOKEN`
through the Supervisor Core-API proxy (the add-on already sets
`homeassistant_api: true`), so there is nothing to configure. It can create and
edit automations, scripts, and scenes; call any service; read entity states;
and, over WebSocket, manage helpers, dashboards, and the area/label/floor/entity
registries. Run `ha-cli --help` inside the add-on for the full command
reference.

```bash
ha-cli config                                   # connectivity check
ha-cli get config/automation/config/<id>        # read one automation
ha-cli post config/automation/config/<id> @new.json   # create/update it
ha-cli call automation.reload                   # apply YAML-mode changes
ha-cli ws '{"type":"config/area_registry/list"}'
```

Security notes:

- The Supervisor proxy token grants **admin-equivalent** Core API access (it can
  call any service and edit any UI-managed configuration), but it cannot reach
  the raw YAML files or other add-ons' data. For a tighter scope, set
  `HA_BASE_URL`/`HA_TOKEN` (or the `ha_mcp_token` option) to a limited Home
  Assistant user's long-lived token — `ha-cli` prefers those when present.
- The guidance instructs Claude to read each object and show you the intended
  change before writing, but Claude Code's own tool-permission prompts remain
  the real gate: each `ha-cli` call still needs your approval unless
  `permission_mode` is set to `bypass`.
- Set `enable_ha_api_helper: false` to remove both the guidance block and the
  helper's registration if you do not want Claude configuring Home Assistant.

## Custom scripts

The add-on includes the repository standard custom-script executor. On first
start, it seeds `claude_desktop.sh` in the add-on config directory. Commands in
that script run during startup, allowing local customization without rebuilding
the image.

## Data and cache locations

Persistent state is stored in the configured `data_location` (default
`/data/data`):

- Claude Desktop sign-in: `~/.config/Claude` (token encrypted via
  gnome-keyring; keyring DB in `~/.local/share/keyrings`)
- Claude Code settings, hooks, sessions, plugins, and permission mode:
  `~/.claude`
- Headroom, RTK, and TokenSave user state: their standard paths below the
  shared home
- TokenSave repository indexes: `.tokensave/` inside each explicitly configured
  project
- Codex authentication and configuration: `~/.codex`; the verified executable
  and subscription-only launcher live in persistent `/data/codex/bin`

Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and
`$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
