# Home assistant add-on: Claude Desktop

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Project Maintenance][maintenance-shield]

Run Claude Desktop in a LinuxServer.io Selkies add-on, with Headroom MCP
context compression, RTK Bash-output acceleration, and code-intelligence
tooling wired in by default.

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
Claude Code configuration (`~/.claude`), hooks, and MCP servers automatically.

- **Claude Desktop** uses Headroom through its MCP tools.
- **Claude Code sessions inside Desktop** get the same MCP servers via
  `~/.claude.json` and RTK's `PreToolUse` Bash hook via
  `~/.claude/settings.json`.
- **gnome-keyring** provides the Secret Service backend Electron needs to
  persist sign-in and dispatch permission grants across restarts.

## Features

- Claude Desktop in single-app Selkies mode with Home Assistant ingress.
- Official Claude Code stable package powering Desktop cowork/dispatch
  sessions.
- Persistent `$HOME` at the configured `data_location` (default `/data/data`),
  preserving Desktop and Claude Code state across restarts.
- Persistent sign-in through a bundled, auto-unlocked gnome-keyring.
- Optional runtime Claude Desktop updates from Anthropic's apt repository.
- Optional extra apt and pip package installation (pip installs use `uv` for
  speed).
- Baked-in `git`, GitHub CLI (`gh`), and `ripgrep`.
- Custom script support through the repository standard `claude_desktop.sh`.
- Bundled optimization tools: Headroom (MCP + local proxy), RTK, tokensave,
  and Caveman — each individually switchable.
- Optional Home Assistant MCP bridge so Claude can query and control Home
  Assistant.
- Headroom dashboard exposed on mapped port `8787`.
- Low-power defaults for GPU mapping, Selkies frame rate, and volatile caches.

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `PUID` / `PGID` | `0` / `0` | Numeric user and group applied by the LinuxServer initialization. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `auto_update` | `true` | Upgrade `claude-desktop` from Anthropic's apt repository at startup. |
| `install_headroom` | `true` | Register the Headroom MCP server and run the supervised local proxy/dashboard. |
| `install_rtk` | `true` | Configure RTK's Claude Code `PreToolUse` hook. |
| `install_tokensave` | `true` | Register the tokensave code-intelligence MCP server for Desktop and Claude Code. |
| `install_caveman` | `true` | Install the Caveman Claude Code plugin in the persistent Claude home. |
| `install_github_cli` | `true` | Enable setup checks for the baked-in `git` and `gh` commands. |
| `github_token` | | Optional GitHub token used to authenticate `gh` and Git operations. |
| `github_username` | | Optional global Git author name. |
| `github_email` | | Optional global Git author email. |
| `enable_ha_mcp` | `false` | Register Home Assistant's MCP server in Claude (requires `ha_mcp_token`). |
| `ha_mcp_url` | `http://homeassistant:8123/mcp_server/sse` | SSE endpoint of Home Assistant's MCP Server integration. |
| `ha_mcp_token` | | Home Assistant long-lived access token used by the MCP bridge. |
| `additional_apps` | | Comma-separated Debian apt packages to install at startup. |
| `additional_pip` | | Comma-separated pip packages installed at startup (via `uv`). |
| `data_location` | `/data/data` | Persistent home directory for Claude and tooling. |
| `env_vars` | `[]` | Additional environment variables exported inside the container. |

## Headroom behavior

When `install_headroom` is enabled, the add-on registers `headroom mcp serve`
in Claude Desktop and Claude Code, and starts a supervised local Headroom
backend. Claude can use `headroom_compress`, `headroom_retrieve`, and
`headroom_stats` through MCP.

Claude Desktop overrides `ANTHROPIC_BASE_URL`, so it is deliberately launched
without proxy injection; the MCP integration is the supported path.

The Headroom dashboard is available at:

```text
http://<home-assistant-host>:8787/dashboard
```

through the default `8787/tcp` port mapping. Treat this endpoint as sensitive:
it serves your local network only — do not expose it directly to the public
internet, and unmap the port in the add-on **Network** section if you do not
want it reachable at all.

## Home Assistant MCP bridge

To let Claude query and control Home Assistant:

1. In Home Assistant, add the **Model Context Protocol Server** integration
   (Settings → Devices & services → Add integration).
2. Create a long-lived access token (your profile → Security).
3. Set `enable_ha_mcp: true` and paste the token into `ha_mcp_token` in the
   add-on configuration, then restart the add-on.

The add-on bridges Claude to the integration's SSE endpoint with `mcp-proxy`.
Override `ha_mcp_url` only if your Home Assistant instance is not reachable as
`homeassistant:8123` from add-ons.

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
- Claude Code settings, hooks, sessions, and plugins: `~/.claude`
- Headroom, RTK, and tokensave user state: their standard paths below the
  shared home

Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and
`$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
