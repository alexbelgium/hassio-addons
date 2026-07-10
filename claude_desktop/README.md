# Home assistant add-on: Claude Desktop

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Project Maintenance][maintenance-shield]

Run Claude Desktop and an optional persistent Claude Code web terminal in one
LinuxServer.io Selkies add-on.

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install **Claude Desktop**.
3. Start the add-on and open the web UI from the sidebar.
4. Sign in with your Claude account from the Desktop app.

Claude Desktop sign-in requires a claude.ai plan that supports the Desktop app.
API keys are not accepted by the Desktop application. Anthropic's Linux beta
currently does not include Computer Use or dictation.

## Architecture

Claude Desktop and Claude Code run as separate clients inside the same add-on.
They share the persistent home directory, Git credentials, repositories, Claude
Code configuration, Headroom storage, and RTK configuration, but they do not
share or hand off a conversation.

- **Claude Desktop** uses Headroom through its MCP tools.
- **Claude Code** uses Headroom's supported `headroom wrap claude` integration.
- **RTK** filters Claude Code Bash output through its `PreToolUse` hook.
- **tmux** keeps the terminal session running when the browser disconnects.

## Features

- Claude Desktop in single-app Selkies mode.
- Home Assistant ingress support for Claude Desktop.
- Official Claude Code stable package installed in the same image.
- Optional authenticated `ttyd` web terminal on port `7681`.
- Persistent `tmux` session shared by reconnecting terminal clients.
- Persistent `$HOME` under `/data/data`, preserving Desktop and Claude Code
  sign-in state across restarts.
- Optional runtime Claude Desktop updates from Anthropic's apt repository.
- Optional extra apt and pip package installation.
- Baked-in `git`, GitHub CLI (`gh`), `ripgrep`, and terminal tooling.
- Custom script support through the repository standard `claude_desktop.sh`.
- Optional bundled Claude Code optimization tools: Headroom, RTK, and Caveman.
- Headroom dashboard exposed on mapped port `8787` when enabled.
- Low-power defaults for GPU mapping, Selkies frame rate, and volatile caches.

## Claude Code terminal setup

The terminal is enabled in the add-on configuration but remains unavailable
until authentication is configured. Port `7681` is not mapped by default.

1. Set `terminal_password`, or set the existing `PASSWORD` option as a fallback.
2. Optionally set `terminal_username` and `terminal_workspace`.
3. Map container port `7681` to a host port in the add-on **Network** section.
4. Restart the add-on.
5. Open `http://<home-assistant-host>:7681` and sign in with the configured
   terminal credentials.

The terminal opens in a persistent tmux session. Closing the browser detaches
from tmux rather than terminating commands that are already running.

Start the optimized Claude Code path with:

```shell
claude-headroom
```

This invokes `headroom wrap claude`, which starts or reuses the local Headroom
proxy and launches Claude Code with the required routing. The RTK hook remains
active through the shared `~/.claude/settings.json` configuration.

To bypass Headroom for troubleshooting, run:

```shell
claude-direct
```

Running `claude` directly is equivalent to the direct path. The first Claude
Code launch may require its own account authentication; Desktop and Claude Code
store separate client credentials even though both live under the same
persistent home directory.

Do not expose the terminal port directly to the public internet. Prefer a VPN,
Tailscale, or another trusted private network in addition to ttyd authentication.

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `PUID` / `PGID` | `0` / `0` | User and group used for persistent data ownership. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports and fallback terminal password. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `auto_update` | `true` | Upgrade `claude-desktop` from Anthropic's apt repository at startup. |
| `enable_terminal` | `true` | Enable the supervised Claude Code web-terminal service. |
| `terminal_username` | `claude` | Username used by ttyd basic authentication. |
| `terminal_password` | | Terminal password; falls back to `PASSWORD`. The service idles when neither is set. |
| `terminal_workspace` | | Initial directory; defaults to `<data_location>/workspace`. |
| `install_headroom` | `true` | Enable Headroom MCP for Desktop and the local proxy used by `claude-headroom`. |
| `install_rtk` | `true` | Configure RTK's Claude Code `PreToolUse` hook. |
| `install_caveman` | `true` | Install the Caveman Claude Code plugin in the persistent Claude home. |
| `install_github_cli` | `true` | Enable setup checks for the baked-in `git` and `gh` commands. |
| `github_token` | | Optional GitHub token used to authenticate `gh` and Git operations. |
| `github_username` | | Optional global Git author name. |
| `github_email` | | Optional global Git author email. |
| `ha_smart_context` | `true` | Enable Home Assistant smart context support for Claude tooling. |
| `enable_ha_mcp` | `true` | Enable Home Assistant MCP support for Claude tooling. |
| `dangerously_skip_permissions` | `false` | Expose Claude Code's dangerous permission-skip option. |
| `additional_apps` | | Comma-separated Debian apt packages to install at startup. |
| `additional_pip` | | Comma-separated pip packages installed with `--break-system-packages`. |
| `data_location` | `/data/data` | Persistent home directory for both Claude clients and tooling. |
| `env_vars` | `[]` | Additional environment variables exported inside the container. |

Standard SMB and local-disk options from the repository are also available.

## Headroom behavior

When `install_headroom` is enabled, the add-on registers `headroom mcp serve` in
Claude Desktop and starts a supervised local Headroom backend. Desktop can use
`headroom_compress`, `headroom_retrieve`, and `headroom_stats` through MCP.

Claude Desktop overrides `ANTHROPIC_BASE_URL`, so it is deliberately launched
without proxy injection. The web terminal instead provides `claude-headroom`,
which uses Headroom's supported Claude Code wrapper.

The Headroom dashboard remains available at:

```text
http://<home-assistant-host>:8787/dashboard
```

when the `8787/tcp` port is mapped.

## Custom scripts

The add-on includes the repository standard custom-script executor. On first
start, it seeds `claude_desktop.sh` in the add-on config directory. Commands in
that script run during startup, allowing local customization without rebuilding
the image.

## Data and cache locations

Persistent state is stored in `data_location`:

- Claude Desktop sign-in: `~/.config/Claude`
- Claude Code settings, hooks, sessions, and plugins: `~/.claude`
- Default terminal workspace: `~/workspace`
- Headroom and RTK user state: their standard paths below the shared home

Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and
`$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
