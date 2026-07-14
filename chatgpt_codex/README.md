# Home Assistant add-on: ChatGPT Codex

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Project Maintenance][maintenance-shield]

Run the official OpenAI Codex CLI in a persistent Home Assistant ingress terminal. The optimized path uses `headroom wrap codex`, with RTK handling command-output compression before results reach Codex.

> The repository already contains an unrelated add-on named **Codex** for comic archives. This coding-agent add-on therefore uses the slug `chatgpt_codex`.

## Features

- Latest stable Codex, Headroom, RTK, ttyd, and Rust toolchain versions are resolved during every Docker build; tool versions are not pinned in the Dockerfile.
- Official Codex CLI static binary for `amd64` and `aarch64`.
- Home Assistant authenticated, administrator-only ingress; no unauthenticated terminal port is exposed.
- Persistent `$HOME`, Codex authentication, settings, sessions, Headroom state, and RTK statistics.
- Persistent `tmux` session that survives browser disconnects.
- `headroom wrap codex` as the default launch path.
- Baked-in RTK with native Codex initialization.
- Optional Headroom output shaping and code-aware compression.
- Direct Codex fallback for troubleshooting.
- Device-code login helper designed for a remote or headless container.
- Baked-in Git, GitHub CLI, ripgrep, jq, SSH client, and common terminal tools.
- Optional GitHub CLI authentication and Git author configuration.
- Optional extra apt and pip packages.
- Local and SMB mount support through the repository standard modules.

## Installation and first login

1. Install **ChatGPT Codex** from this add-on repository.
2. Keep the default `data_location` and `workspace`, or select writable mounted paths.
3. Start the add-on and open its web UI.
4. Codex starts automatically through Headroom.
5. When prompted to authenticate, follow the device-code instructions. You can also exit Codex and run:

```shell
codex-login
```

Codex supports ChatGPT sign-in and API-key authentication. The device-code flow is the recommended option for this headless add-on.

## Launch commands

Optimized default:

```shell
codex-headroom
```

This runs:

```shell
headroom wrap codex
```

Headroom starts its local proxy, configures Codex routing and MCP support, and uses RTK as the CLI context tool.

Direct troubleshooting path:

```shell
codex-direct
```

Check optimization status and measured savings:

```shell
headroom doctor
headroom perf
rtk gain
```

## Persistence

The terminal attaches every browser connection to the same `tmux` session. Closing the browser detaches the client but does not stop Codex or commands running in the session.

Persistent data is stored below `data_location`:

- Codex state: `~/.codex`
- Headroom state and metrics: `~/.headroom`
- RTK state: its normal paths below the persistent home
- Default workspace: `~/workspace`

## Options

| Option | Default | Description |
| --- | --- | --- |
| `data_location` | `/data/data` | Persistent home. Must be below `/data`, `/share`, `/media`, `/config`, or `/mnt`. |
| `workspace` | `<data_location>/workspace` | Initial project directory. Leave empty to follow `data_location`. |
| `PUID` / `PGID` | `0` / `0` | Runtime user and group used by the LinuxServer `abc` account. |
| `TZ` | | Optional timezone, for example `Europe/Brussels`. |
| `auto_start_codex` | `true` | Start Codex automatically when the tmux session is first created. |
| `use_headroom` | `true` | Use `headroom wrap codex`; disabling this starts Codex directly. |
| `headroom_output_shaper` | `true` | Enable Headroom output-token shaping. |
| `headroom_code_aware` | `true` | Enable Headroom AST-aware code compression. |
| `github_token` | | Authenticate GitHub CLI and Git operations. |
| `github_username` / `github_email` | | Configure the global Git author. |
| `additional_apps` | | Comma-separated Debian packages installed at startup. |
| `additional_pip` | | Comma-separated Python packages installed at startup. |
| `localdisks` / `networkdisks` | | Optional local-disk and SMB mounts supported by the repository modules. |
| `env_vars` | `[]` | Additional environment variables exported in the container. |

Configuration changes affecting the launch command apply to a newly created tmux session. To recreate it, exit Codex and run `tmux kill-session -t codex`, then reopen the add-on web UI.

## Security

The add-on deliberately does not enable Codex approval or sandbox bypass flags. Codex can execute commands and edit files available inside the configured workspace, so only mount locations you intend it to access.

The terminal is exposed only through Home Assistant administrator-only ingress. Do not add an unauthenticated direct port mapping. Treat `github_token`, Codex authentication data, and the persistent home as secrets and include them only in trusted backups.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2026.svg
