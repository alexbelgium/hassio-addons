## 2.2.0 (2026-09-24)

- Moved the application data out of the add-on's private `/data` volume and
  into `/config/data`, so it is visible from Home Assistant as
  `/addon_configs/xxx-free_games_claimer/data` instead of needing a
  `docker exec`. Everything the application writes now lands there: `fgc.db`,
  the `screenshots/` captures, the `browser/` profiles, `TurboVNC.log` and
  upstream's debug dumps (#3081).
- An existing `/data` payload is copied over once on the first start of this
  version: `fgc.db` with its rollback journal and its pre-migration backup,
  `browser/`, `screenshots/`, the `epic-games.json`, `prime-gaming.json` and
  `gog.json` claim histories, the legacy `data/` directory and the migration
  marker. Logs and last-run debug dumps are not copied, because the application
  regenerates them. The copy is staged and renamed into place, so an interrupted
  migration is retried rather than leaving a half-copied database or browser
  profile. Nothing is deleted from `/data`: the migration needs temporary free
  space roughly equal to the existing data, can take a few minutes for a large
  browser profile, and leaves the old copy in place so a downgrade still
  works.
- **The migrated `browser/` directory holds authenticated store sessions and
  `config.env` holds the account credentials. Both are now readable by any
  add-on with access to `addon_configs`, such as File Editor or Samba. Treat
  that directory as secret and do not share or back it up publicly.**
- Removed the `cp -rnf /fgc/* /data/` line from `20-folders.sh`, which copied
  the whole upstream source tree into the persistent volume on every start.
  Nothing read those copies. They are left in `/data` and can be deleted by
  hand.
- Stopped applying a recursive `chmod 777` to the configuration directory on
  every start, which would otherwise have made the migrated browser profile
  and credentials world-writable.

 
## 2.1.1 (2026-09-12)
- Update to latest version from P-Adamiec/Free-Games-Claimer-Remaster (changelog : https://github.com/P-Adamiec/Free-Games-Claimer-Remaster/releases)
- Upstream tag : 1.9
- Migrate legacy add-on configuration map names to current app configuration terminology.
## 2.1.0 (2026-08-24)

- Updated the pinned upstream from Free Games Claimer Remaster 1.1 to 1.6,
  which adds the Ubisoft giveaway, Fab, AliExpress and Epic mobile stores,
  fixed daily scheduler times, the `VNC_URL` notification link override, and a
  fix for the `--accept-lang` flag that made every store's browser detectable
  as automated.
- Mirrored upstream's Chromium hardening: `xdg-open` is neutralised and an
  `AutoLaunchProtocolsFromOrigins` policy is installed, so app-scheme links
  cannot open a blocking dialog in the VNC session.
- Disabled upstream's release-update notification by default. It tells the user
  to run `docker compose pull`, while the add-on is updated through the Home
  Assistant add-on store. Set `NOTIFY_UPDATES=true` in `config.env` to receive
  it anyway.
- Reworded the add-on description so the store list reads as partial rather
  than exhaustive; the full list is in the README.
- The default store selection is unchanged: existing installations keep
  claiming from Epic, Prime Gaming and GOG until `STORES` is edited.
- Replaced the pinned upstream commit with `ARG BUILD_UPSTREAM`, which names an
  upstream release tag, and re-enabled the repository updater for this add-on.
  Upstream releases are now picked up automatically instead of requiring a
  manual commit pin. Upstream's development tags are excluded: `lastversion`
  reports the `v1.7d` development tag as release `1.7`, for which no source
  archive exists, so an unfiltered update would have broken the build.

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
