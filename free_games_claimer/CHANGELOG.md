## 2.0.1 (2026-07-17)

- Aligned the pull-request build context with the production builder by copying
  the shared Home Assistant helper scripts before building the add-on.
- Fixed aarch64 and amd64 PR validation failing on unresolved Dockerfile
  `COPY` instructions. Runtime and migration behavior are unchanged.

## 2.0.0 (2026-07-17)

- Replaced the abandoned `vogler/free-games-claimer` upstream with
  `P-Adamiec/Free-Games-Claimer-Remaster`.
- Reworked the image build for the remaster's Python, Chromium, TurboVNC, and
  noVNC runtime on both amd64 and aarch64.
- Preserved the previous default one-shot behavior and Epic, Prime Gaming, and
  GOG store selection.
- Kept noVNC on port 6080 for upgrade compatibility.
- Added `RUN_ONCE` and `STORES` options while retaining `CMD_ARGUMENTS` as a
  deprecated compatibility input.
- Added an automatic, idempotent migration of legacy Epic, Prime Gaming, and
  GOG JSON claim history into the remaster SQLite database.
- Preserved legacy files for rollback and documented the required one-time
  Chromium login when a Firefox session cannot be migrated.
- Pinned the reviewed upstream source commit and paused generic automatic
  updates so the add-on's independent `2.x` version cannot regress to `1.x`.
- Updated the configuration template, upstream metadata, and documentation.
- Added support for configuring extra environment variables via the `env_vars`
  add-on option.

## 1.8 (2025-05-17)

- Update to latest version from vogler/free-games-claimer (changelog: https://github.com/vogler/free-games-claimer/releases)

## 1.7 (2025-03-08)

- Update to latest version from vogler/free-games-claimer (changelog: https://github.com/vogler/free-games-claimer/releases)

## 1.6-6 (2024-12-29)

- Minor bugs fixed

## 1.6-5 (2024-12-13)

- Minor bugs fixed

## 1.6-4 (2024-12-07)

- Major change: switch to the new Home Assistant add-on configuration logic.
  Configuration files were migrated from
  `/config/hassio_addons/free_games_claimer` to the private add-on configuration
  directory available through compatible file browser add-ons.

## 1.6-3 (2024-12-05)

- Minor bugs fixed

## 1.6-2 (2024-12-05)

- Minor bugs fixed

## 1.6 (2023-12-30)

- Update to latest version from vogler/free-games-claimer

## 1.5 (2023-11-04)

- Update to latest version from vogler/free-games-claimer

## 1.4 (2023-05-27)

- Update to latest version from vogler/free-games-claimer

## 1.4-5 (2023-05-26)

- Minor bugs fixed

## 1.4-4 (2023-05-26)

- Minor bugs fixed

## 1.4-3 (2023-05-26)

- Minor bugs fixed

## 1.4-2 (2023-05-25)

- Minor bugs fixed

## NOT_WORKING (2023-05-22)

- Minor bugs fixed
- Initial release
