# Home assistant add-on: Claude Desktop

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Project Maintenance][maintenance-shield]

Run the Claude Desktop Linux app inside a LinuxServer.io Selkies container and stream it through Home Assistant ingress.

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install **Claude Desktop**.
3. Start the add-on and open the web UI from the sidebar.
4. Sign in with your Claude account from the Desktop app.

Claude Desktop sign-in requires a claude.ai plan that supports the Desktop app. API keys are not accepted by the Desktop application. Anthropic's Linux beta does not include Computer Use or dictation.

## Features

- Claude Desktop in single-app Selkies mode.
- Home Assistant ingress support.
- Persistent `$HOME` under `/config/data`, preserving Claude Desktop and Claude Code sign-in state across restarts.
- Optional runtime Claude Desktop updates from Anthropic's apt repository.
- Optional extra apt and pip package installation.
- Baked-in `git` and GitHub CLI (`gh`) with optional startup credential configuration.
- Custom script support through the repository standard `claude_desktop.sh` script.
- Optional bundled Claude Code optimization tools: headroom, rtk, and caveman.
- Low-power defaults: GPU device mapping, `AUTO_GPU=1`, `SELKIES_FRAMERATE=30`, `/tmp` tmpfs, and `$HOME/.cache` redirected to `/tmp/cache`.

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `PUID` / `PGID` | `0` / `0` | User and group used for persistent data ownership. |
| `TZ` | | Optional timezone, for example `America/New_York`. |
| `KEYBOARD` | | Optional Selkies keyboard layout. |
| `PASSWORD` | | Optional password for direct Selkies ports. Set this before exposing ports `3000` or `3001`. |
| `DRINODE` | | Optional GPU device override for Selkies. |
| `DNS_server` | `8.8.8.8` | DNS server used by the standard DNS module. |
| `auto_update` | `true` | Check Anthropic's apt repository and upgrade `claude-desktop` at add-on startup. |
| `install_headroom` | `true` | Make the baked-in `headroom` command available and log a usage hint. |
| `install_rtk` | `true` | Configure the rtk Claude Code `PreToolUse` hook in the persistent Claude Code settings. |
| `install_caveman` | `true` | Install the caveman Claude Code plugin into the persistent Claude Code home. |
| `install_github_cli` | `true` | Enable first-start checks and setup for the baked-in `git` and `gh` commands. |
| `github_token` | | Optional GitHub personal access token used to authenticate `gh` and configure Git credentials for GitHub. |
| `github_username` | | Optional global Git author name. |
| `github_email` | | Optional global Git author email. |
| `additional_apps` | | Comma-separated Debian apt packages to install at startup, for example `htop,git`. |
| `additional_pip` | | Comma-separated pip packages to install at startup. Installs use `--break-system-packages`. |
| `data_location` | `/config/data` | Persistent home directory location. Keep this persistent so Claude sign-in survives restarts. |
| `networkdisks`, `cifsusername`, `cifspassword`, `cifsdomain` | | Standard SMB mount options. |
| `localdisks` | | Standard local disk mount option. |
| `env_vars` | `[]` | Extra environment variables to export into the container. This can override `SELKIES_*` defaults. |

## Custom scripts

The add-on includes the repository standard custom-script executor. On first start, it seeds a `claude_desktop.sh` file in the add-on config directory from the shared template. Commands in that script run during startup, allowing local customization without rebuilding the image.

## Data and cache locations

Persistent state is stored in the configured `data_location`. Claude Desktop stores sign-in data below `~/.config/Claude`, and Claude Code/tool configuration is stored below `~/.claude`. Volatile cache data is redirected to `/tmp/cache` through `$XDG_CACHE_HOME` and `$HOME/.cache`.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
