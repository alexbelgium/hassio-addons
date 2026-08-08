## 0.0.101.1 (2026-08-08)
- Fix broken builds: upstream retagged `:latest` to the v1.0.0 rewrite on 2026-07-31, so this add-on was building on an image its rootfs does not support. `build_from` is now pinned to `chrisleekr/binance-trading-bot:0.0.101`, the frozen v0 line this add-on targets.
- This also resolves the `externally-managed-environment` (PEP 668) pip failure, which was a symptom of the same retag: the v1 image ships a much newer Alpine than the v0 line this add-on is built against.
- Upstream tracking is paused: v1.0.0 is a complete rewrite with no in-place upgrade (datastore moved to Postgres + TimescaleDB), so it needs an add-on rewrite rather than a version bump.

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 0.0.101 (2025-06-13)
- Update to latest version from chrisleekr/binance-trading-bot (changelog : https://github.com/chrisleekr/binance-trading-bot/releases)

## 0.0.100 (2025-02-21)
- Update to latest version from chrisleekr/binance-trading-bot (changelog : https://github.com/chrisleekr/binance-trading-bot/releases)

## 0.0.99 (2024-11-09)
- Update to latest version from chrisleekr/binance-trading-bot (changelog : https://github.com/chrisleekr/binance-trading-bot/releases)

## 0.0.98 (2023-04-15)

- Update to latest version from chrisleekr/binance-trading-bot

## 0.0.97 (2023-03-24)

- Update to latest version from chrisleekr/binance-trading-bot
- Implemented healthcheck

## 0.0.96 (2023-03-04)

- Update to latest version from chrisleekr/binance-trading-bot
- First version
