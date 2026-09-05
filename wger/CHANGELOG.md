## 2.6.4 (2026-09-05)

- Fix the add-on failing to start with `ImproperlyConfigured: Set the DJANGO_DB_ENGINE environment variable`: wger 2.7 removed the implicit sqlite fallback from its settings, so the database is now declared explicitly through `DJANGO_DB_ENGINE` / `DJANGO_DB_DATABASE`, still pointing at the persistent `/data/database.sqlite`
- Replace the misleading "Unable to find Python settings containing database path" warning with an informational message, as wger no longer hardcodes that path

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
