## 1.6.0.4 (2026-11-25)
- Ingress: clicking inside the remote session now gives it keyboard focus in the Home Assistant sidebar. Guacamole blocks the browser's usual focus-on-click there, so keys kept going to Home Assistant, whose keyboard shortcuts could then open dialogs over the session (#3285)

## 1.6.0.3 (2026-11-25)
- Ingress: focus the add-on again whenever Guacamole changes view, such as when a connection opens, and not only when the page first loads, so keys reach the remote session without pressing Tab first (#3285)

## 1.6.0.2 (2026-11-23)
- ⚠️ **IMPORTANT: MAKE A BACKUP OF THE ADD-ON BEFORE UPDATING.** This version upgrades the database from PostgreSQL 13 to 18 in place. If anything goes wrong, or if you want to go back to an earlier version of the add-on, restoring that backup is the safe way back: earlier versions cannot read a PostgreSQL 18 database
- ⚠ PostgreSQL 13 -> 18: build from `abesnier/guacamole:1.6.0-pg18`, as upstream stops updating its PostgreSQL 13 images in January 2027 (#3278). The upstream image upgrades the database in place at the first start: it downloads the PostgreSQL 13 server for the upgrade (internet access needed), and replaces `/config/postgres` only after `pg_upgrade` and a reindex succeed. The PostgreSQL 13 database is kept as `/config/postgres.pg13.bak` (delete it once everything works). If the upgrade fails, `/config/postgres` is unchanged and the add-on cannot start until the cause in the log is fixed
- Upstream image: build from the maintained `abesnier/guacamole:1.6.0` tag instead of the floating `latest`, and let the updater follow plain `X.Y.Z` releases instead of the discontinued `-bullseye` tags (#3278). The database is still PostgreSQL 13
- Startup: remove dead code for a port 80/SSL server and a `SUBFOLDER` variable that this add-on and image never use
- Fix the redirect meant to silence the `.database-version` read error: the upstream service scripts run under `sh` (dash), where `&>` does not redirect

## 1.6.0-bullseye-5 (2026-11-22)
- Ingress: focus the add-on when its page loads in the sidebar panel, so keys go to the remote session instead of Home Assistant shortcuts (#3274)
- Build: create the syslog socket with perl, since the upstream image (now Ubuntu 22.04) no longer ships python3

## 1.6.0-bullseye-4 (24-09-2026)
- Ingress: new `login_with_ha_user` option to sign in with your Home Assistant username instead of always `guacadmin` (#3087)
- Startup log and README warn when the `auth-header` extension is enabled while port 8080 is published, since that port bypasses Ingress and lets anyone log in as any user

- Migrate legacy add-on configuration map names to current app configuration terminology.
## 1.6.0-bullseye-3 (13-03-2026)
- Fix PROXY_ALLOWED_IPS_REGEX default from invalid regex "*" to ".*"

## 1.6.0-bullseye-2 (26-02-2026)
- Minor bugs fixed

## 1.6.0-bullseye (2025-12-24)
- Update to latest version from abesnier/guacamole

##  (2025-12-23)
- Update to latest version from abesnier/guacamole
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 1.6.0-12 (2025-10-02)
- Added configuration to enable the history recording storage extension with a configurable recording path

## 1.6.0-11 (2025-09-16)
- Minor bugs fixed
## 1.6.0-10 (2025-09-16)
- Minor bugs fixed
## 1.6.0-9 (2025-09-16)
- Addon is now working again

## 1.6.0-4 (2025-07-24)
- Minor bugs fixed

## 1.6.0-3 (2025-07-24)
- Minor bugs fixed

## 1.6.0-2 (2025-07-20)
- Minor bugs fixed

## 1.6.0-bullseye (2025-07-18)
- Minor bugs fixed

## 1.5.5-bullseye (2025-01-25)
- Update to latest version from abesnier/guacamole

## 1.5.5-pg17 (2025-01-25)
- Update to latest version from abesnier/guacamole

## githubtest (2025-01-25)
- Update to latest version from abesnier/guacamole
## 1.5.5 (2024-10-08)
- Info : https://hub.docker.com/r/abesnier/guacamole

## TEST3 (2024-03-18)
- Minor bugs fixed
## TEST2 (2024-03-18)
- Minor bugs fixed
## TEST1 (2024-03-17)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/hassio_addons/guacamole to a folder only accessible from my Filebrowser addon called /app_configs/something-guacamole. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/ https://github.com/alexbelgium/hassio-addons/issues/1309

## testnoupload (2023-11-11)

- Update to latest version from abesnier/guacamole

## testarmv7 (2023-10-07)

- Update to latest version from abesnier/guacamole

## test (2023-09-23)

- Update to latest version from abesnier/guacamole

## github-pg15 (2023-08-26)

- Update to latest version from abesnier/guacamole

## simple (2023-08-26)

- Update to latest version from abesnier/guacamole

## github-pg15 (2023-08-12)

- Update to latest version from abesnier/guacamole

## test (2023-06-24)

- Update to latest version from abesnier/guacamole

## alpine (2023-06-10)

- Update to latest version from abesnier/guacamole

## 1.5.2-pg15 (2023-06-03)

- Update to latest version from abesnier/guacamole

## 1.5.1-pg15 (2023-05-27)

- Update to latest version from abesnier/guacamole
## 1.5.1-2 (2023-05-04)

- Minor bugs fixed

## 1.5.1-pg14 (2023-04-23)

- Update to latest version from abesnier/guacamole
## 1.5.1 (2023-04-22)

- Minor bugs fixed

## 1.5.0 (2023-03-18)

- Update to latest version from MaxWaldorf/guacamole
- Implemented healthcheck

## 1.4.3 (2023-03-04)

- Update to latest version from MaxWaldorf/guacamole
- Switch upstream image to abesnier/guacamole
- Allow custom fonts (thanks @fischer-felix)
- WARNING : update to supervisor 2022.11 before installing

## 1.4.2 (2022-05-14)

- Update to latest version from MaxWaldorf/guacamole

## 1.4.1 (2022-05-11)

- Update to latest version from MaxWaldorf/guacamole
- Initial release
