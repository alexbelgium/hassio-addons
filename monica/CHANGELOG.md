## 5.0.0b5-2 (26-02-2026)
- Minor bugs fixed

## 5.0.0b5 (2025-12-27)
- Update to latest version from monicahq/monica (changelog : https://github.com/monicahq/monica/releases)
## v5.0_beta5-8 (2025-12-07)
- Generate and persist a secure Meilisearch master key when none is provided or when configured keys are too short.

## v5.0_beta5-7 (2025-12-06)
- Minor bugs fixed
## v5.0_beta5-6 (2025-11-17)
- Rename the Meilisearch configuration option to `meilisearch_key` and align schema/options with Home Assistant add-on best practices.

## v5.0_beta5-5 (2025-11-16)
- Add a configurable `MEILISEARCH_KEY` option so the bundled Meilisearch can be secured (or left blank to disable auth) without relying on custom env vars.

## v5.0_beta5-4 (2025-11-15)
- Increment version for rebuilt add-on
## v5.0_beta5-3 (2025-11-15)
- Minor bugs fixed
## v5.0_beta6 (2025-01-06)
- Bundled an internal Meilisearch service and configure Monica to use it for full-text search by default.
- Ensure the init script only launches the bundled Meilisearch when `MEILISEARCH_URL` points to localhost and wait for the health endpoint before starting Monica.

## v5.0_beta5 (2025-11-14)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## v5.0_beta4-2 (2024-12-07)
- Increase default storage size to 1024 Mo

## v5.0_beta4 (2024-12-06)
- First version
