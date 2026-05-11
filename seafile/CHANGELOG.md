
## 12.0.18-5 (2026-05-11)
- Fix file uploads and downloads through a reverse proxy (e.g. Nginx Proxy Manager) by:
  - Writing `SEAFILE_SERVER_HOSTNAME` and `SEAFILE_SERVER_PROTOCOL` to `seafile.env` so Seafile knows its external URL
  - Setting `host = 0.0.0.0` in the `[fileserver]` section of `seafile.conf` so the fileserver binds to all interfaces
  - Adding `CSRF_TRUSTED_ORIGINS` to `seahub_settings.py` to prevent Django CSRF rejections on HTTPS setups
  - Making `FILE_SERVER_ROOT` optional (`str?`) so it can be left empty when the reverse proxy handles `/seafhttp` routing

## 12.0.18-4 (2026-05-10)
- Fix admin account creation by writing `conf/admin.txt` and seeding `seafile.env` with `SEAFILE_ADMIN_EMAIL`/`SEAFILE_ADMIN_PASSWORD` so the upstream `check_init_admin.py` no longer falls back to an interactive prompt (#2685)

## 12.0.18-3 (2026-05-10)
- Fix MariaDB connection on HAOS >=17.3 by forcing IPv4 host resolution (#2688)

## 12.0.18-2 (2026-02-22)
- Fix download URLs containing incorrect `/seafhttp` prefix on first run by re-applying URL configuration after upstream init scripts complete.

## 12.0.18 (2026-03-20)
- Fix `env_vars` handling so extra environment variables are exported correctly.

## 12.0.17 (2026-03-12)
- Ensure `SERVICE_URL` and `FILE_SERVER_ROOT` are written to the active Seafile config path.

## 12.0.14 (2025-12-28)
- Update to latest version from franchetti/seafile-arm

##  (2025-12-23)
- Update to latest version from franchetti/seafile-arm
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 12.0.16 (2026-02-15)
- Handle list-based `database` options correctly so SQLite configurations skip MySQL initialization.

## 12.0.15 (2025-12-18)
- Normalize `SERVICE_URL` and `FILE_SERVER_ROOT` values in `conf/seahub_settings.py` based on the add-on configuration to generate valid download links.

## 12.0.14 (2025-09-13)
- Update to latest version from franchetti/seafile-arm

## testing (2023-06-10)

- Update to latest version from franchetti/seafile-arm
## 10.0.1-fixed (2023-05-22)

- Minor bugs fixed
- Fix : allow app to start

## 10.0.1 (2023-05-19)

- Update to latest version from franchetti/seafile-arm
- Feat : cifsdomain added

## 10.0.0 (2023-03-24)

- Update to latest version from franchetti/seafile-arm

## 9.0.10 (2023-01-28)

- Update to latest version from franchetti/seafile-arm
- Allow setting server url
- Allow custom env variables through config.yaml

## v9.0.14-pro (2022-12-01)

- Update to latest version from haiwen/seahub
- WARNING : update to supervisor 2022.11 before installing

## v9.0.13-pro (2022-11-11)

- Update to latest version from haiwen/seahub

## v9.0.12-pro (2022-11-05)

- Update to latest version from haiwen/seahub

## v9.0.11-pro (2022-10-29)

- Update to latest version from haiwen/seahub

## v9.0.10-pro (2022-10-13)

- Update to latest version from haiwen/seahub

## v9.0.9-pro (2022-09-24)

- Update to latest version from haiwen/seahub

## v9.0.9-server (2022-09-20)

- Update to latest version from haiwen/seahub

## v9.0.8-pro (2022-09-09)

- Update to latest version from haiwen/seahub

## v9.0.7-server (2022-08-09)

- Update to latest version from haiwen/seahub

## v9.0.7-pro (2022-08-04)

- Update to latest version from haiwen/seahub

## v9.0.6-pro (2022-07-02)

- Update to latest version from haiwen/seahub

## v9.0.6-server (2022-06-18)

- Update to latest version from haiwen/seahub

## v9.0.5-server (2022-06-11)

- Update to latest version from haiwen/seahub
- Initial release
