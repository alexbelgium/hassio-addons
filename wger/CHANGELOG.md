## 2.6.4 (04-09-2026)

- Fix the add-on failing to start on a fresh install with `django.core.exceptions.ImproperlyConfigured: Set the DJANGO_DB_ENGINE environment variable`. The upstream `wger/server` image stopped shipping database defaults, and `settings/main.py` reads `DJANGO_DB_ENGINE` and `DJANGO_DB_DATABASE` with no fallback, so the add-on now sets them explicitly to sqlite at `/data/database.sqlite` — the same location the previous startup rewrite produced, so existing databases keep working.
- Set `DJANGO_PERFORM_MIGRATIONS=True`, as upstream's own docker deployment does, so an existing database gets new migrations applied when the add-on is rebuilt against a newer upstream release.
- Drop the startup rewrite of the database path in the Python settings: upstream no longer hardcodes `/home/wger/db/database.sqlite` anywhere, so the rewrite silently did nothing and only logged a warning.
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration file will have migrated from /config/addons_config/wger to a folder only accessible from my Filebrowser addon called /addon_configs/xxx-wger. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration is automatic only for a config.yaml sitting at the default /config/addons_config/wger/config.yaml. If you had pointed CONFIG_LOCATION somewhere else inside the homeassistant config folder, or had a custom script at /homeassistant/addons_autoscripts/wger.sh, move the file to /addon_configs/xxx-wger/ by hand and update the option. Please be sure to update all your links ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## 2.6.3 (2026-08-01)

- Version renamed from `2.6-dev-3`, which Home Assistant could not order and therefore could not reliably offer as an update: every number of the previous version is kept, as a section of its own. The addon itself and the upstream version it tracks are unchanged

## 2.6-dev-3 (2026-06-16)
- Fix fresh-install startup by making the persistent `/data/static` and `/data/media` directories writable by the `wger` user without recursively changing all of `/data`.
- Preserve existing persistent data by reusing `/data/database.sqlite` when present, and migrating a legacy `/home/wger/db/database.sqlite` only if no persistent database exists yet.
- Make nginx startup idempotent and fail loudly if its configuration is invalid, instead of masking nginx startup errors that can leave the add-on web port closed.

## 2.6-dev-2 (2026-06-16)
- Fix startup script database path rewrite by switching the `settings.py` matching with `*.py` since last update moved the settings.py file into several files within the settings folder
## 2.6-dev (2026-04-23)
- Update to latest version from wger/server
## 2.5-dev-3 (2026-03-09)
- Fix startup script database path rewrite by scanning `/home` for matching `settings.py` files and patching all matches.

## 2.5-dev-2 (25-02-2026)
- Minor bugs fixed

## 2.5-dev (2026-01-21)
- Update to latest version from wger/server
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.4-11 (2025-09-19)
- Minor bugs fixed
## 2.4-10 (2025-09-19)
- Minor bugs fixed
## 2.4-9 (2025-09-01)
- Minor bugs fixed
## 2.4-6 (2025-09-01)
- Minor bugs fixed
## 2.4-4 (2025-09-01)
- Minor bugs fixed
## 2.4-3 (2025-09-01)
- Minor bugs fixed
## 2.4-2 (2025-07-15)

- Minor bugs fixed

## 2.4-dev (2025-04-12)

- Update to latest version from wger/server

## 2.3-dev (2023-12-09)

- Update to latest version from wger/server

## 2.2-dev-8 (2023-11-09)

- Minor bugs fixed

## 2.2-dev-6 (2023-08-03)

- Minor bugs fixed

## 2.2-dev-5 (2023-03-11)

- Bug updates
- Implement healthcheck

## 2.2-dev (2022-12-10)

- Update to latest version from wger/devel
- Allow custom env variables through config.yaml
