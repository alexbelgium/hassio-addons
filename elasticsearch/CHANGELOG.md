 
## 8.19.19 (2026-07-21)
- Update to latest version from elastic/elasticsearch (changelog : https://github.com/elastic/elasticsearch/releases)
## 8.19.18-3 (14-07-2026)
- Force a fresh image pull for users left on a stale cached image (some upgrades kept running the old Elasticsearch 7.17.9 image, failing with `mv: cannot move '/data/config' ... Permission denied` and `AccessDeniedException[/usr/share/elasticsearch/data/nodes/0]`). Fully stop and update the add-on so Home Assistant pulls this build.
- Replaced the cryptic `Permission denied` failure with a clear message when the add-on is not running as root (the state that caused the failure above).

## 8.19.18-2 (14-07-2026)
- Minor bugs fixed
## 8.19.18 (2026-07-14)

- Upgrade to Elasticsearch 8.19.18 (#2849). Note: despite the previous add-on version reading `8.14.3`, the shipped image was still Elasticsearch 7.17.9 — the Dockerfile upstream version was never bumped. This release actually delivers 8.x, making the add-on compatible with the `homeassistant-elasticsearch` integration (requires 8.14+).
- Automatic data migration: existing 7.17 data is upgraded in place by Elasticsearch on first start (one-way; can take a while on large datasets). A migration guard aborts with a clear message on unsupported paths (downgrades, or data more than one major version old). Take a Home Assistant backup before updating.
- The previous bundled config directory is archived to `/data/config.bak-<old-version>` during major upgrades; re-apply custom settings to the new config if needed.
- Security (`xpack.security.enabled`) defaults to `false` to preserve the previous plain-HTTP behavior. Override by adding `ES_SETTING_XPACK_SECURITY_ENABLED` (or any `ES_SETTING_XPACK_SECURITY_*` variable) in the add-on's `env_vars` option.
- Fixed the `env_vars` add-on option, which previously had no effect: variables are now exported before Elasticsearch starts.
- Removed the `ingest-attachment` plugin install: it is a bundled module since Elasticsearch 8.0.
- Startup persistence logic rewritten as a proper init script (`/usr/local/bin/addon-init.sh`) instead of line-number-based entrypoint patching.
- Added `updater.json` so upstream 8.19.x releases are tracked automatically (pinned to the 8.19 line: 9.x cannot read indices created in 7.x).
- The upstream 8.x image ends the build as a non-root user with a read-only entrypoint; the Dockerfile now switches to root for the build steps that patch/install into it. The container also starts as root (unchanged from 7.17.9) so `addon-init.sh` can chown/move pre-existing `/data` content that may be owned by root from earlier installs; unlike 7.17.9's own entrypoint, the upstream 8.x entrypoint no longer drops privileges before starting Elasticsearch (which refuses to run as root), so `addon-init.sh` now does that itself via `chroot --userspec=1000:0` once its root-only work is done.
- `env_vars` names starting with a digit are now rejected before export instead of crashing the entrypoint.
- Fixed a startup failure (`mv: cannot move '/data/config' ... Permission denied`) on upgrade from an existing 7.17.9 install, caused by an earlier fix in this same release that switched the runtime user to non-root before this fix was in place.
- Fixed a second regression from that same fix: without a privilege drop before starting Elasticsearch, both fresh installs and upgrades would fail Elasticsearch's own root-check ("can not run elasticsearch as root").

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
