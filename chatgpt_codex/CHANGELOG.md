## 0.144.3-3 (14-07-2026)
- Minor bugs fixed
## 0.144.3-2 (14-07-2026)

- Initial ChatGPT Codex add-on.
- Added a persistent, administrator-only Home Assistant ingress terminal backed by tmux.
- Made `headroom wrap codex` the default launch path.
- Configured Docker builds to install the latest stable Codex, Headroom, RTK, ttyd, and Rust toolchain versions without hard-coded tool version pins.
- Added RTK native Codex initialization and savings reporting.
- Added device-code authentication and direct Codex fallback helpers.
- Added persistent configuration, GitHub CLI integration, mount support, and safe defaults.
- Made the default workspace follow a custom `data_location`.
