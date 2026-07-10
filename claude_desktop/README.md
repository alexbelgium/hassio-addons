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
They share the configured persistent home directory, Git credentials,
repositories, Claude Code configuration, Headroom storage, and RTK
configuration, but they do not share or hand off a conversation.

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
- Persistent `$HOME` at the configured `data_location` (default `/data/data`),
  preserving Desktop and Claude Code state across restarts.
- Optional runtime Claude Desktop updates from Anthropic's apt repository.
- Optional extra apt and pip package installation.
- Baked-in `git`, GitHub CLI (`gh`), `ripgrep`, and terminal tooling.
- Custom script support through the repository standard `claude_desktop.sh`.
- Optional bundled Claude Code optimization tools: Headroom, RTK, and Caveman.
- Headroom dashboard exposed on mapped port `8787` when enabled.
- Low-power defaults for GPU mapping, Selkies frame rate, and volatile caches.

## Claude Code terminal setup

The terminal service is enabled in the add-on configuration but remains
unavailable until authentication is configured. Port `7681` is not mapped by
default.

1. Set a unique `terminal_password`. The existing `PASSWORD` option is accepted
   only as a compatibility fallback.
2. Optionally set `terminal_username` and `terminal_workspace`.
3. Map container port `7681` to a host port in the add-on **Network** section.
4. Restart the add-on.
5. Reach `http://<home-assistant-host>:7681` only through an encrypted VPN or an
   HTTPS reverse proxy, then sign in with the configured terminal credentials.

The terminal opens in a persistent tmux session. Closing the browser detaches
from tmux rather than terminating commands that are already running.

Start the optimized Claude Code path with:

```shell
claude-headroom
```

This reuses the supervised Headroom proxy on `127.0.0.1:8787` and launches
Claude Code with the required routing. Headroom is told not to install RTK
because the add-on already maintains the RTK hook in
`~/.claude/settings.json`.

To bypass Headroom for troubleshooting, run:

```shell
claude-direct
```

Running `claude` directly is equivalent to the direct path. The first Claude
Code launch may require its own account authentication; Desktop and Claude Code
store separate client credentials even though both use the configured
persistent home directory.

### Multiple concurrent clients

Every browser connection attaches to the same tmux session. Concurrent clients
therefore see the same terminal, keystrokes, and resize events. This is useful
for reconnecting to one long-running session, but it is not an isolated
multi-user terminal.

### Terminal user and permissions

The service drops privileges to the LinuxServer `abc` account before starting
ttyd. The effective numeric UID and GID follow the configured `PUID` and `PGID`.
Using `PUID: 0` can provide root-equivalent access inside the add-on; use a
non-zero UID/GID where your storage permissions allow it.

The configured workspace must resolve to the persistent home directory or a
subdirectory of `/share`, `/media`, `/mnt`, `/data`, or `/config`. Existing
directories are never re-owned by the terminal service and must already be
readable, writable, and searchable by `abc`.

### Terminal security

The direct ttyd endpoint uses HTTP Basic Authentication without TLS.
Credentials and terminal traffic are unencrypted on the network. ttyd also
receives its Basic Authentication credential as a process argument, so it is
visible to processes with sufficient access inside the container.

Do not expose port `7681` directly to the public internet. Use a VPN such as
WireGuard or Tailscale, or place the endpoint behind an HTTPS reverse proxy.
Use a unique `terminal_password` rather than reusing the Selkies `PASSWORD`.

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `PUID` / `PGID` | `0` / `0` | Numeric user and group applied by the LinuxServer initialization. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports and compatibility fallback for terminal authentication. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `auto_update` | `true` | Upgrade `claude-desktop` from Anthropic's apt repository at startup. |
| `enable_terminal` | `true` | Enable the supervised Claude Code web-terminal service. |
| `terminal_username` | `claude` | Username used by ttyd Basic Authentication. |
| `terminal_password` | | Dedicated terminal password. The service idles when this and `PASSWORD` are empty. |
| `terminal_workspace` | | Initial directory; defaults to `<data_location>/workspace`. |
| `install_headroom` | `true` | Enable Headroom MCP for Desktop and the supervised local proxy reused by `claude-headroom`. |
| `install_rtk` | `true` | Configure RTK's Claude Code `PreToolUse` hook. |
| `install_caveman` | `true` | Install the Caveman Claude Code plugin in the persistent Claude home. |
| `install_github_cli` | `true` | Enable setup checks for the baked-in `git` and `gh` commands. |
| `github_token` | | Optional GitHub token used to authenticate `gh` and Git operations. |
| `github_username` | | Optional global Git author name. |
| `github_email` | | Optional global Git author email. |
| `ha_smart_context` | `true` | Enable Home Assistant smart context support for Claude tooling. |
| `enable_ha_mcp` | `true` | Enable Home Assistant MCP support for Claude tooling. |
| `dangerously_skip_permissions` | `false` | Reserved compatibility option; it is not applied by the terminal launcher. |
| `additional_apps` | | Comma-separated Debian apt packages to install at startup. |
| `additional_pip` | | Comma-separated pip packages installed with `--break-system-packages`. |
| `data_location` | `/data/data` | Persistent home directory for both Claude clients and tooling. |
| `env_vars` | `[]` | Additional environment variables exported inside the container. |

## Headroom behavior

When `install_headroom` is enabled, the add-on registers `headroom mcp serve` in
Claude Desktop and starts a supervised local Headroom backend. Desktop can use
`headroom_compress`, `headroom_retrieve`, and `headroom_stats` through MCP.

Claude Desktop overrides `ANTHROPIC_BASE_URL`, so it is deliberately launched
without proxy injection. The web terminal instead provides `claude-headroom`,
which reuses the supervised proxy through Headroom's `--no-proxy` mode. RTK
setup remains owned by the add-on through Headroom's `--no-rtk` mode.

The Headroom dashboard remains available at:

```text
http://<home-assistant-host>:8787/dashboard
```

when the `8787/tcp` port is mapped. Treat this endpoint as sensitive and do not
expose it directly to the public internet.

## Custom scripts

The add-on includes the repository standard custom-script executor. On first
start, it seeds `claude_desktop.sh` in the add-on config directory. Commands in
that script run during startup, allowing local customization without rebuilding
the image.

## Data and cache locations

Persistent state is stored in the configured `data_location` (default
`/data/data`):

- Claude Desktop sign-in: `~/.config/Claude`
- Claude Code settings, hooks, sessions, and plugins: `~/.claude`
- Default terminal workspace: `~/workspace`
- Headroom and RTK user state: their standard paths below the shared home

Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and
`$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
