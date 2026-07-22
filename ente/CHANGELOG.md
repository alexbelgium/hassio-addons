 
## 4.4.23 (2026-06-11)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
## 1.7.24 (2026-06-05)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
## 4.4.22-7 (04-06-2026)
- Minor bugs fixed
## 4.4.22-6 (04-06-2026)
- Fix SIGPIPE (exit 141) on startup: tr piped to head -c against /dev/urandom
  now suppresses the expected SIGPIPE under set -o pipefail
## 4.4.22-5 (04-06-2026)
- Fix AppArmor profile name (was copied from qbittorrent, could collide with that add-on)
- Expose Accounts (3001), Auth (3003) and Cast (3004) ports so the login/2FA web apps are reachable
- Default external Postgres port to 5432 when DB_PORT is left blank
- Write the correct DB host/port to museum.yaml when using an external database
- Exclude minio-data and postgres folders from Home Assistant backups
## 4.4.22-4 (04-06-2026)
- Minor bugs fixed
## 4.4.22-3 (04-06-2026)
- Remove DISABLE_WEB_UI option, web UI is now always enabled
- Make MinIO internal-only (127.0.0.1) since museum proxies S3 operations
- Fix web UI API origin: use ENTE_ENDPOINT_URL so browsers can reach the API
- Hardcode MinIO credentials internally (no longer user-configurable)
- Remove dead options: MINIO_DATA_LOCATION, MINIO_ROOT_USER, MINIO_ROOT_PASSWORD

## 4.4.22-2 (04-06-2026)
- Minor bugs fixed

## 4.4.23 (2026-06-03)
- Fix nginx rewrite loop on /index.html causing 500 Internal Server Error in Web UI

## 4.4.22 (2026-05-16)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.21 (2026-05-09)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.20 (2026-04-23)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.19 (2026-04-04)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.3.28 (2026-03-28)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.7.21 (2026-03-07)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.3.16 (2026-02-28)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.3.15 (2026-02-23)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.17 (2026-02-21)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.16 (2026-02-14)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.17 (2026-02-07)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.7.18 (2026-02-04)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.7.17 (2026-01-30)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
## 4.4.15 (2026-01-03)
- Minor bugs fixed

## 4.4.13 (2025-12-20)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.12 (2025-11-29)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.10 (2025-11-22)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.11 (2025-11-15)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.10 (2025-11-08)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "4.4.6-3" (2025-11-05)
- Minor bugs fixed
## "4.4.6-2" (2025-11-04)
- Minor bugs fixed
## "4.4.6" (2025-11-01)
- Minor bugs fixed

## 4.4.6 (2025-11-01)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.5 (2025-10-11)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 1.2.9 (2025-10-04)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.4 (2025-08-09)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)

## 4.4.3 (2025-07-25)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
## 4.4.0-2 (2025-07-20)
- Minor bugs fixed

## 4.4.0 (2025-07-18)
- Update to latest version from ente-io/ente (changelog : https://github.com/ente-io/ente/releases)
## 1.1.57-3 (2025-07-18)
- Minor bugs fixed
## 1.1.57-2 (2025-07-17)
- Minor bugs fixed
## 1.1.57 (2025-07-17)
- Minor bugs fixed

