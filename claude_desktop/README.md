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
- When `permission_mode: bypass` is selected while `PUID` is `0`, the add-on
  automatically remaps the shared `abc` desktop account to an unused non-root
  UID before Selkies and Claude Desktop start. Claude Code refuses bypass mode
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
- Optional runtime Claude Desktop updates from Anthropic's apt repository.
- Optional extra apt and pip package installation (pip installs use `uv`).
- Baked-in `git`, GitHub CLI (`gh`), `ripgrep`, `jq`, `shellcheck`, `yamllint`,
  `hadolint`, and `actionlint`.
- Custom script support through the repository standard `claude_desktop.sh`.
- Bundled optimization tools: Headroom, RTK, and TokenSave; Caveman remains
  available as an opt-in plugin.
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
| `PUID` / `PGID` | `0` / `0` | Numeric user and group applied by LinuxServer initialization. In bypass mode, a root `PUID` is automatically replaced at runtime by an unused non-root UID while the configured group is retained. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `auto_update` | `true` | Upgrade `claude-desktop` from Anthropic's apt repository at startup. |
| `permission_mode` | `auto` | Claude Code permission policy: `strict`, `auto`, or `bypass`. |
| `install_headroom` | `true` | Register Headroom MCP and run the supervised local proxy. |
| `headroom_wrap_claude_code` | `true` | Route PATH-based Claude Code launches through the already-running Headroom proxy. |
| `expose_headroom_dashboard` | `false` | Bind Headroom to all interfaces. Port `8787/tcp` must also be mapped manually. |
| `install_rtk` | `true` | Configure RTK's Claude Code `PreToolUse` Bash hook. |
| `install_tokensave` | `true` | Install TokenSave's complete global Claude integration. |
| `tokensave_project_paths` | `[]` | Explicit absolute Git repository paths to initialize or sync at startup. |
| `install_caveman` | `false` | Install the third-party Caveman Claude Code plugin at startup. |
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
add-on is configured with `PUID: 0`, selecting `bypass` remaps only the shared
`abc` runtime account to an available non-root UID (preferring `1000`, then
`911`) before storage ownership and Desktop startup. Its configured primary
GID is retained, so group-based access to mounted Home Assistant paths remains
available. Strict and auto modes keep the configured identity unchanged.

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

The dashboard is disabled externally by default. To expose it:

1. Set `expose_headroom_dashboard: true`.
2. Map `8787/tcp` in the add-on **Network** section.
3. Open `http://<home-assistant-host>:8787/dashboard`.

The dashboard is unauthenticated. Do not publish this port to the public
internet.

## Diagnostics

Run the following inside the add-on through a custom script or container console:

```bash
claude-tools-doctor.sh
```

The report checks the tool binaries, configuration switches, configured and
effective runtime identities, redacted MCP registrations, Claude hooks,
permission mode, Headroom health, TokenSave indexes, routing, and recorded
savings. It never prints MCP environment values because the Home Assistant MCP
entry can contain a long-lived token.

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

Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and
`$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
