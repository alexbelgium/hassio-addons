## 0.34.21.1 (24-10-2026)

- Fix `getcwd: cannot access parent directories` at startup: the image now starts from `/` instead of upstream's `/workspace`, which is replaced by a symlink to `/config/workspace` during init

## 0.34.21 (2026-10-24)

- Update to latest version from letta-ai/letta-code (changelog: <https://github.com/letta-ai/letta-code/releases>)
- Use 0.34.21: upstream tagged 0.34.22 and 0.34.23 but their image publish failed, so `ghcr.io/letta-ai/letta-code:0.34.23` does not exist
- Updater: only follow GitHub releases with assets (`github_havingasset`), so tags whose image publish failed are skipped

## 0.34.19 (2026-10-22)

- Initial release, based on upstream letta-ai/letta-code 0.34.19 (changelog: <https://github.com/letta-ai/letta-code/releases>)
- Stateful AI agent platform and App Server with long-term memory (MemFS), skills, and multi-agent reasoning
- Direct App Server access on port 4500 for WebSockets, health probes, and OpenAI-compatible API routes
- Persistent storage for agents, workspaces, and credentials in `/config`
