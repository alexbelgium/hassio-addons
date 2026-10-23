# Home Assistant Add-on: Letta Code

Stateful AI agent platform and App Server with long-term memory, skills, and multi-agent reasoning.

[Letta Code](https://github.com/letta-ai/letta-code) is an open-source development agent and App Server by Letta AI. It features stateful agents that remember across sessions using MemFS, execute tools in local or cloud sandboxes, and expose an OpenAI-compatible API and WebSocket server.

## Features

- Stateful AI development agents with persistent memory (MemFS)
- Built-in App Server for WebSocket and HTTP agent orchestration
- OpenAI-compatible API (`/v1/models`, `/v1/chat/completions`, `/v1/responses`)
- Local and cloud execution backends
- Persistent workspace and agent storage in `/config`

## Installation

1. Add this repository to Home Assistant.
2. Install the **Letta Code** add-on.
3. Configure your API keys in the add-on's **Configuration** tab (see below).
4. Start the add-on.
5. Enable port `4500` under the **Network** section in the add-on's **Configuration** tab, then connect clients to `http://homeassistant:4500` (or `ws://homeassistant:4500/ws`).

## Configuration

| Option | Default | Description |
| -------- | --------- | ------------- |
| `backend` | `local` | Agent execution backend: `local` or `cloud`. |
| `openai_api` | `true` | Enable OpenAI-compatible endpoints (`/v1/models`, `/v1/chat/completions`, etc.). |
| `token` | *(generated)* | App Server capability token. If not specified, a secure random token is generated in `/config/app-server-token`. |
| `PUID` / `PGID` | `0` / `0` | User and group ID to run the add-on as and own persistent files in `/config`. |
| `TZ` | *none* | Container timezone (e.g. `America/New_York` or `UTC`). |
| `env_vars` | `[]` | Extra environment variables such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `LETTA_API_KEY`. |

### Setting API Keys

Provide your LLM API keys via the `env_vars` option:

```yaml
env_vars:
  - name: OPENAI_API_KEY
    value: sk-...
  - name: ANTHROPIC_API_KEY
    value: sk-ant-...
```

## Endpoints & API Access

Letta Code serves its App Server on port `4500`:

- **Direct Access (Port 4500):** Port `4500` is disabled by default for security so capability tokens are not sent over unencrypted connections. To enable direct WebSocket and OpenAI API access, specify port `4500` under the **Network** section in the add-on's **Configuration** tab (or route through a reverse proxy terminating TLS/HTTPS):
  - **Health Check:** `http://homeassistant:4500/healthz`
  - **Readiness:** `http://homeassistant:4500/readyz`
  - **Server Info:** `http://homeassistant:4500/app-server-info`
  - **WebSocket Protocol:** `ws://homeassistant:4500/ws`
  - **OpenAI API Compatible:** `http://homeassistant:4500/v1/chat/completions`

## Storage & Persistence

Letta Code stores state, databases, credentials, and MemFS memory in `/config/.letta`, which is symlinked to `/root/.letta`. Project workspace files reside in `/config/workspace` (symlinked to `/workspace`). All state persists across add-on restarts and container rebuilds.

## Support & Links

- [Letta Code Documentation](https://github.com/letta-ai/letta-code)
- [Letta AI Discord Community](https://discord.gg/letta)
- [Add-on Repository Issues](https://github.com/alexbelgium/hassio-addons/issues)
