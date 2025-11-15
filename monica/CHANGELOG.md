## v5.0_beta5-4 (15-11-2025)
- Increment version for rebuilt add-on
## v5.0_beta5-3 (15-11-2025)
- Minor bugs fixed
## v5.0_beta6 (06-01-2025)
- Bundled an internal Meilisearch service and configure Monica to use it for full-text search by default.
- Ensure the init script only launches the bundled Meilisearch when `MEILISEARCH_URL` points to localhost and wait for the health endpoint before starting Monica.

## v5.0_beta5 (14-11-2025)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## v5.0_beta4-2 (07-12-2024)
- Increase default storage size to 1024 Mo

## v5.0_beta4 (06-12-2024)
- First version
