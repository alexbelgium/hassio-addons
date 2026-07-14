## 8.19.18 (2026-07-14)

- Upgrade to Elasticsearch 8.19.18 (#2849). Note: despite the previous add-on version reading `8.14.3`, the shipped image was still Elasticsearch 7.17.9 — the Dockerfile upstream version was never bumped. This release actually delivers 8.x, making the add-on compatible with the `homeassistant-elasticsearch` integration (requires 8.14+).
- Automatic data migration: existing 7.17 data is upgraded in place by Elasticsearch on first start (one-way; can take a while on large datasets). A migration guard aborts with a clear message on unsupported paths (downgrades, or data more than one major version old). Take a Home Assistant backup before updating.
- The previous bundled config directory is archived to `/data/config.bak-<old-version>` during major upgrades; re-apply custom settings to the new config if needed.
- Security (`xpack.security.enabled`) defaults to `false` to preserve the previous plain-HTTP behavior. Override by adding `ES_SETTING_XPACK_SECURITY_ENABLED` (or any `ES_SETTING_XPACK_SECURITY_*` variable) in the add-on's `env_vars` option.
- Fixed the `env_vars` add-on option, which previously had no effect: variables are now exported before Elasticsearch starts.
- Removed the `ingest-attachment` plugin install: it is a bundled module since Elasticsearch 8.0.
- Startup persistence logic rewritten as a proper init script (`/usr/local/bin/addon-init.sh`) instead of line-number-based entrypoint patching.
- Added `updater.json` so upstream 8.19.x releases are tracked automatically (pinned to the 8.19 line: 9.x cannot read indices created in 7.x).
- The upstream 8.x image ends the build as a non-root user with a read-only entrypoint; the Dockerfile now switches to root for the build steps that patch/install into it and restores the Elasticsearch user before runtime.
- `env_vars` names starting with a digit are now rejected before export instead of crashing the entrypoint.

## 8.14.3-3 (2026-06-19)
- Fix startup failing with `chroot: cannot change root directory` by allowing `capability sys_chroot` in the AppArmor profile (#2709)
- Fix AppArmor profile name (was `inadyn_addon`, colliding with several other add-ons); renamed to `elasticsearch_addon`

## 8.14.3-2 (2025-11-18)
- 8.14.3-1 (2025-11-18)
  - Added `env_vars` option to support custom environment variables from the add-on configuration.

- BREAKING CHANGE : upgrade to v8.14.3. You'll need to rebuild your indexes

## v7
- Implemented healthcheck
- WARNING : update to supervisor 2022.11 before installing
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation
- Initial build
